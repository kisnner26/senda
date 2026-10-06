import Foundation
@preconcurrency import CoreLocation
import Network
import Observation

@MainActor @Observable
final class Recorder: NSObject, @preconcurrency CLLocationManagerDelegate {
    var isRecording = false
    var status = "listo para salir"
    var activeID: UUID?
    @ObservationIgnored var onNetworkAvailable: (() -> Void)?
    private let manager = CLLocationManager()
    private let probe = NetworkProbe()
    private let monitor = NWPathMonitor()
    private var store: TripStore?
    private var latestLocation: CLLocation?
    private var lastAttempt: Date?
    private var task: Task<Void, Never>?
    private var loop: Task<Void, Never>?
    private var interface = "desconocida"
    private var pendingStart = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .otherNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        monitor.pathUpdateHandler = { [weak self] path in
            let value = path.usesInterfaceType(.cellular) ? "móvil" : path.usesInterfaceType(.wifi) ? "wifi" : "sin ruta"
            let available = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.interface = value
                if available { self?.onNetworkAvailable?() }
            }
        }
        monitor.start(queue: .init(label: "senda.network"))
    }

    func start(store: TripStore) {
        guard !isRecording else { return }
        guard !store.isDemo else { status = "sal del modo de demostración para grabar"; return }
        guard !store.loadFailed else { status = "no se puede grabar sin recuperar el historial"; return }
        self.store = store
        switch manager.authorizationStatus {
        case .notDetermined:
            pendingStart = true
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            let trip = Trip()
            store.trips.insert(trip, at: 0)
            store.save()
            activeID = trip.id
            latestLocation = nil
            lastAttempt = nil
            isRecording = true
            status = "buscando ubicación"
            manager.startUpdatingLocation()
            loop = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(12))
                    guard !Task.isCancelled else { return }
                    self?.attempt()
                }
            }
        default: status = "permite la ubicación desde ajustes del iphone"
        }
    }

    func stop() {
        pendingStart = false
        loop?.cancel()
        task?.cancel()
        loop = nil
        task = nil
        manager.stopUpdatingLocation()
        if let store, let index = store.trips.firstIndex(where: { $0.id == activeID }) {
            store.trips[index].endedAt = .now
            store.save()
        }
        isRecording = false
        activeID = nil
        status = "recorrido guardado"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if pendingStart, let store {
            pendingStart = false
            start(store: store)
        }
        if isRecording && (manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted) {
            stop()
            status = "se retiró el permiso de ubicación"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRecording, let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        latestLocation = location
        if location.horizontalAccuracy > 100 {
            status = manager.accuracyAuthorization == .reducedAccuracy
                ? "activa ubicación precisa en ajustes del iphone"
                : "esperando gps preciso; intenta cerca de una ventana o afuera"
        }
        attempt()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = "ubicación no disponible; esperando gps"
    }

    private func attempt() {
        guard isRecording, task == nil, let location = latestLocation,
              location.horizontalAccuracy <= 100,
              abs(location.timestamp.timeIntervalSinceNow) <= 20,
              lastAttempt.map({ Date.now.timeIntervalSince($0) >= 12 }) ?? true,
              let tripID = activeID else { return }
        let now = Date.now
        if let previous = lastAttempt, now.timeIntervalSince(previous) > 45 {
            append(Measurement(timestamp: now.addingTimeInterval(-0.001), latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude, accuracy: location.horizontalAccuracy,
                latency: nil, quality: .unknown, interface: interface), to: tripID)
        }
        lastAttempt = now
        status = "midiendo conexión"
        let currentInterface = interface
        task = Task { [weak self, probe] in
            let (quality, latency) = await probe.measure()
            guard !Task.isCancelled, let self, self.activeID == tripID else { return }
            self.append(Measurement(timestamp: now, latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude, accuracy: location.horizontalAccuracy,
                latency: latency, quality: quality, interface: currentInterface), to: tripID)
            if self.isRecording { self.status = quality.label }
            self.task = nil
        }
    }

    private func append(_ sample: Measurement, to id: UUID) {
        guard let store, let index = store.trips.firstIndex(where: { $0.id == id }) else { return }
        store.trips[index].samples.append(sample)
        store.save()
        if store.trips[index].samples.count >= 10000 {
            stop()
            status = "límite de 10 000 puntos; recorrido guardado"
        }
    }
}
