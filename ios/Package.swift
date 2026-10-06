// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SendaMetrics",
    platforms: [.macOS(.v26)],
    products: [.library(name: "Senda", targets: ["Senda"])],
    targets: [
        .target(name: "Senda", path: "Senda",
            exclude: ["Services", "Views", "Components", "Resources", "App/SendaApp.swift", "Models/Screen.swift", "Models/PreviewTrip.swift"],
            sources: ["Models/Trip.swift", "Models/TripSelection.swift", "Models/Measurement.swift", "Models/ConnectionQuality.swift", "App/Palette.swift"]),
        .testTarget(name: "SendaTests", dependencies: ["Senda"], path: "Tests"),
    ]
)
