import SwiftUI
import MapKit

struct RouteMapView: View {
    var trip: Trip?
    var isRecording = false
    var locationStatus = ""
    var currentPosition: Measurement?
    @State private var position = MapCameraPosition.automatic

    var body: some View {
        VStack(spacing: 12) {
            Map(position: $position) {
                if let fix = currentPosition, isRecording {
                    MapCircle(center: fix.coordinate, radius: fix.accuracy)
                        .foregroundStyle(Palette.orange.opacity(0.12))
                        .stroke(Palette.orange.opacity(0.6), lineWidth: 1)
                    Annotation("aquí · ± \(Int(fix.accuracy.rounded())) m", coordinate: fix.coordinate) {
                        Circle().fill(Palette.orange).frame(width: 14, height: 14)
                            .overlay { Circle().stroke(.white, lineWidth: 3) }
                    }
                }
                if let trip {
                    ForEach(trip.samples.enumerated(), id: \.element.id) { index, sample in
                        if index > 0, sample.quality != .unknown, trip.samples[index - 1].quality != .unknown,
                           sample.timestamp.timeIntervalSince(trip.samples[index - 1].timestamp) <= 45 {
                            MapPolyline(coordinates: [trip.samples[index - 1].coordinate, sample.coordinate])
                                .stroke(sample.quality.color, lineWidth: 5)
                        }
                        if sample.quality == .failed || sample.quality == .unknown || index == 0 || index == trip.samples.count - 1 {
                            Annotation(sample.quality.label, coordinate: sample.coordinate) {
                                Image(systemName: sample.quality.symbol)
                                    .font(.caption2.bold()).foregroundStyle(.white)
                                    .frame(width: 22, height: 22).background(sample.quality.color, in: .circle)
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                                    .accessibilityLabel(sample.quality.label)
                            }.annotationTitles(.hidden)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls { MapCompass(); MapScaleView() }
            .clipShape(.rect(cornerRadius: 24))
            .overlay(alignment: .topLeading) {
                Text("\(trip?.samples.count ?? 0) puntos / \(trip?.suspectedZones ?? 0) zonas")
                    .font(.caption.monospaced()).padding(12).background(.regularMaterial, in: .capsule).padding(12)
            }
            .overlay {
                if (trip?.samples.isEmpty ?? true) && currentPosition == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "location.slash").font(.title)
                        Text(isRecording ? "esperando el primer punto" : "este recorrido no tiene puntos").font(.headline)
                        Text(isRecording ? locationStatus : "inicia un recorrido y espera una medición antes de terminarlo")
                            .font(.caption).multilineTextAlignment(.center)
                    }.padding(24).background(Palette.paper, in: .rect(cornerRadius: 20))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let fix = currentPosition, isRecording {
                    Button("centrar · ± \(Int(fix.accuracy.rounded())) m", systemImage: "location") {
                        position = .region(MKCoordinateRegion(center: fix.coordinate,
                            latitudinalMeters: max(500, fix.accuracy * 3), longitudinalMeters: max(500, fix.accuracy * 3)))
                    }.font(.caption).padding(12).background(.regularMaterial, in: .capsule)
                }
            }
            HStack(spacing: 12) {
                ForEach(ConnectionQuality.allCases, id: \.self) { quality in
                    VStack(spacing: 5) {
                        Image(systemName: quality.symbol).foregroundStyle(quality.color)
                        Text(quality == .failed ? "fallo" : quality.label).font(.caption2)
                    }.frame(maxWidth: .infinity)
                }
            }.padding(14).background(.white.opacity(0.3), in: .rect(cornerRadius: 18))
            Text("dos fallos consecutivos indican una zona sospechosa. los huecos sin mediciones no cuentan como caídas.")
                .font(.caption).foregroundStyle(Palette.muted).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.horizontal, 24).padding(.bottom, 8)
            .onChange(of: currentPosition == nil) { _, missing in
                if !missing, trip?.samples.isEmpty ?? true { position = .automatic }
            }
            .onChange(of: trip?.id) { position = .automatic }
            .onChange(of: trip?.samples.isEmpty) { _, empty in
                if empty == false { position = .automatic }
            }
    }
}
