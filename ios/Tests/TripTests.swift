import Testing
import Foundation
@testable import Senda

struct TripTests {
    private func sample(_ quality: ConnectionQuality, at seconds: Double, latency: Double? = nil) -> Senda.Measurement {
        Senda.Measurement(timestamp: Date(timeIntervalSince1970: seconds), latitude: 12, longitude: -86,
            accuracy: 5, latency: latency, quality: quality, interface: "móvil")
    }

    @Test func unknownSamplesDoNotBecomeOutages() {
        let trip = Trip(samples: [sample(.stable, at: 0), sample(.unknown, at: 60)])
        #expect(trip.stability == 1)
        #expect(trip.suspectedZones == 0)
    }
    @Test func failureRunsRespectGaps() {
        let trip = Trip(samples: [sample(.failed, at: 0), sample(.failed, at: 12), sample(.failed, at: 24),
            sample(.unknown, at: 90), sample(.failed, at: 100), sample(.failed, at: 160)])
        #expect(trip.suspectedZones == 1)
    }
    @Test func emptyTripHasNoInventedStability() {
        #expect(Trip().stability == nil)
        #expect(Trip().medianLatency == nil)
    }
    @Test func medianAveragesMiddlePair() {
        let trip = Trip(samples: [sample(.stable, at: 0, latency: 10), sample(.stable, at: 12, latency: 30)])
        #expect(trip.medianLatency == 20)
    }
}
