import Foundation
import CoreLocation

struct Measurement: Codable, Identifiable, Sendable {
    var id = UUID()
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var accuracy: Double
    var latency: Double?
    var quality: ConnectionQuality
    var interface: String

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}
