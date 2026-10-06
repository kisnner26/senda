import Foundation

enum PreviewTrip {
    static func make() -> Trip {
        let start = Date.now.addingTimeInterval(-1440)
        let samples = (0..<90).map { index in
            let quality: ConnectionQuality = (37...42).contains(index) || (66...68).contains(index) ? .failed : index % 9 == 0 ? .slow : .stable
            return Measurement(timestamp: start.addingTimeInterval(Double(index) * 12),
                latitude: 12.125 + Double(index) * 0.00004 + sin(Double(index) / 8) * 0.00012,
                longitude: -86.278 + Double(index) * 0.00008,
                accuracy: 8, latency: quality == .failed ? nil : quality == .slow ? 950 : 85 + Double(index % 13) * 8,
                quality: quality, interface: "móvil")
        }
        return Trip(startedAt: start, endedAt: start.addingTimeInterval(1080), samples: samples)
    }
}
