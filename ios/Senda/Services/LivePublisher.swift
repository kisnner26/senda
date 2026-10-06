import Foundation
import Observation

@MainActor @Observable
final class LivePublisher {
    var message = "ubicación en vivo apagada"
    private var task: Task<Void, Never>?
    private var lastAttempt = Date.distantPast

    func update(position: Measurement?, recording: Bool, force: Bool = false) {
        guard UserDefaults.standard.bool(forKey: "liveSharing"), recording,
              let position, abs(position.timestamp.timeIntervalSinceNow) <= 20 else { return }
        guard force || Date.now.timeIntervalSince(lastAttempt) >= 12 else { return }
        guard task == nil else { return }
        lastAttempt = .now
        send(active: true, position: position, sentAt: Date.now.timeIntervalSince1970)
    }

    func disable() {
        task?.cancel()
        task = nil
        let timestamp = Date.now.timeIntervalSince1970
        UserDefaults.standard.set(timestamp, forKey: "liveStopPending")
        retryStop()
    }

    func retryStop() {
        let timestamp = UserDefaults.standard.double(forKey: "liveStopPending")
        guard timestamp > 0 else { return }
        task?.cancel()
        task = nil
        send(active: false, position: nil, sentAt: timestamp)
    }

    private func send(active: Bool, position: Measurement?, sentAt: Double) {
        guard let raw = UserDefaults.standard.string(forKey: "serverURL"),
              let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https", url.host != nil, !CredentialStore.read().isEmpty else {
            message = "guarda la dirección https y el token para compartir"
            return
        }
        let token = CredentialStore.read()
        var payload: [String: Any] = ["active": active, "sentAt": sentAt]
        if let position {
            payload["position"] = ["latitude": position.latitude, "longitude": position.longitude,
                "accuracy": position.accuracy, "timestamp": position.timestamp.timeIntervalSince1970]
        }
        var request = URLRequest(url: url.appendingPathComponent("api/live"))
        request.httpMethod = "PUT"
        request.timeoutInterval = 10
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        task = Task { [weak self] in
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled, let self else { return }
                guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                    self.message = "ubicación pendiente; revisa el servidor y el token"
                    self.task = nil
                    return
                }
                if !active, UserDefaults.standard.double(forKey: "liveStopPending") == sentAt {
                    UserDefaults.standard.removeObject(forKey: "liveStopPending")
                }
                self.message = active ? "compartiendo con tu web privada" : "ubicación en vivo apagada"
                self.task = nil
            } catch {
                guard !Task.isCancelled, let self else { return }
                self.message = active ? "sin conexión; la posición web caduca en 90 s" : "apagado pendiente; la posición web caduca en 90 s"
                self.task = nil
            }
        }
    }
}
