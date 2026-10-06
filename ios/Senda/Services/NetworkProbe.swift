import Foundation

actor NetworkProbe {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 6
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)
    }

    func measure() async -> (ConnectionQuality, Double?) {
        let endpoints = [
            ("https://cp.cloudflare.com/generate_204", 204),
            ("https://www.apple.com/library/test/success.html", 200)
        ]
        for (address, expectedStatus) in endpoints {
            guard let url = URL(string: address), !Task.isCancelled else { continue }
            var request = URLRequest(url: url)
            request.setValue("no-cache, no-store", forHTTPHeaderField: "Cache-Control")
            let start = ContinuousClock.now
            do {
                let (body, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == expectedStatus,
                      http.url?.host == url.host else { continue }
                if expectedStatus == 200 && !(String(data: body, encoding: .utf8)?.contains("<BODY>Success</BODY>") ?? false) { continue }
                let duration = start.duration(to: .now).components
                let ms = Double(duration.seconds) * 1000 + Double(duration.attoseconds) / 1e15
                return (ms > 800 ? .slow : .stable, ms)
            } catch { continue }
        }
        return (.failed, nil)
    }
}
