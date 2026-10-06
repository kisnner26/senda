import SwiftUI

enum ConnectionQuality: String, Codable, Sendable, CaseIterable {
    case stable, slow, failed, unknown

    var label: String {
        switch self {
        case .stable: "estable"
        case .slow: "lenta"
        case .failed: "fallo de conexión"
        case .unknown: "sin datos"
        }
    }

    var color: Color {
        switch self {
        case .stable: Palette.ink
        case .slow: Palette.orange
        case .failed: Palette.rust
        case .unknown: Palette.muted
        }
    }

    var symbol: String {
        switch self {
        case .stable: "circle.fill"
        case .slow: "clock"
        case .failed: "xmark"
        case .unknown: "minus"
        }
    }
}
