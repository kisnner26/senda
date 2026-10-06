import Foundation
import Observation

@MainActor @Observable
final class TripStore {
    var trips: [Trip] = []
    var error: String?
    var isSyncing = false
    let isDemo: Bool
    private(set) var loadFailed = false
    private let file = URL.documentsDirectory.appending(path: "trips.json")

    init() {
        isDemo = ProcessInfo.processInfo.arguments.contains("--demo")
        if isDemo { trips = [PreviewTrip.make()]; return }
        do {
            if FileManager.default.fileExists(atPath: file.path()) {
                trips = try JSONDecoder().decode([Trip].self, from: Data(contentsOf: file))
                // A terminated recording is closed at its last known sample, never silently resumed.
                for index in trips.indices where trips[index].endedAt == nil {
                    trips[index].endedAt = trips[index].samples.last?.timestamp ?? trips[index].startedAt
                }
                save()
            }
        } catch {
            loadFailed = true
            self.error = "no se pudo abrir el historial: \(error.localizedDescription)"
        }
    }

    func save() {
        guard !isDemo, !loadFailed else { return }
        do { try JSONEncoder().encode(trips).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]) }
        catch { self.error = "no se pudo guardar el recorrido: \(error.localizedDescription)" }
    }

    func export() -> URL? {
        let target = URL.temporaryDirectory.appending(path: "senda-recorridos.json")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(trips).write(to: target, options: .atomic)
            return target
        }
        catch { self.error = error.localizedDescription; return nil }
    }

    func sync(server: String, token: String) async throws -> Int {
        guard !isDemo else {
            throw NSError(domain: "senda", code: 3, userInfo: [NSLocalizedDescriptionKey: "los datos de demostración no se sincronizan"])
        }
        guard !isSyncing else { return 0 }
        isSyncing = true
        defer { isSyncing = false }
        guard let base = URL(string: server), base.scheme == "https", base.host != nil, !token.isEmpty else {
            throw NSError(domain: "senda", code: 1, userInfo: [NSLocalizedDescriptionKey: "configura una dirección https y el token del servidor"])
        }
        let pending = trips.filter { !$0.synced && $0.endedAt != nil }
        var count = 0
        for trip in pending {
            var request = URLRequest(url: base.appending(path: "api/trips"))
            request.httpMethod = "POST"
            request.timeoutInterval = 20
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(trip)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "senda", code: 2, userInfo: [NSLocalizedDescriptionKey: "el servidor rechazó la sincronización; revisa el token y la dirección"])
            }
            if let index = trips.firstIndex(where: { $0.id == trip.id }) { trips[index].synced = true }
            save()
            count += 1
        }
        if error?.hasPrefix("sincronización pendiente:") == true { error = nil }
        return count
    }
}
