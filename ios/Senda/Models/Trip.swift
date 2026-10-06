import Foundation
import CoreLocation

struct Trip: Codable, Identifiable, Sendable {
    var id = UUID()
    var startedAt = Date.now
    var endedAt: Date?
    var samples: [Measurement] = []
    var synced = false

    var measured: [Measurement] { samples.filter { $0.quality != .unknown } }
    var stability: Double? {
        guard !measured.isEmpty else { return nil }
        return Double(measured.count { $0.quality != .failed }) / Double(measured.count)
    }
    var medianLatency: Double? {
        let values = samples.compactMap(\.latency).sorted()
        guard !values.isEmpty else { return nil }
        let middle = values.count / 2
        return values.count.isMultiple(of: 2) ? (values[middle - 1] + values[middle]) / 2 : values[middle]
    }
    // Only adjacent failures within the sampling window form a suspected dead zone.
    var suspectedZones: Int {
        var count = 0
        var run = 0
        for (index, sample) in samples.enumerated() {
            let adjacent = index == 0 || sample.timestamp.timeIntervalSince(samples[index - 1].timestamp) <= 45
            if sample.quality == .failed {
                run = adjacent ? run + 1 : 1
                if run == 2 { count += 1 }
            } else { run = 0 }
        }
        return count
    }
    var distance: Double {
        zip(samples, samples.dropFirst()).reduce(0) { sum, pair in
            guard pair.1.timestamp.timeIntervalSince(pair.0.timestamp) <= 45 else { return sum }
            return sum + CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
    }
}
