import Foundation

enum TripSelection {
    static func mapTrip(in trips: [Trip], activeID: UUID?, selectedID: UUID?) -> Trip? {
        if let activeID, let active = trips.first(where: { $0.id == activeID }) { return active }
        if let selectedID, let selected = trips.first(where: { $0.id == selectedID }) { return selected }
        return trips.first(where: { !$0.samples.isEmpty }) ?? trips.first
    }
}
