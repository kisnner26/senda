import SwiftUI

struct DashboardView: View {
    var trip: Trip?
    var recorder: Recorder
    var store: TripStore
    var openMap: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StabilityDial(value: trip?.stability).padding(.top, 4)
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Text("pulso de\nla conexión").font(.headline).lineSpacing(-3)
                            Spacer()
                            Image(systemName: "arrow.up.right").accessibilityHidden(true)
                        }
                        LatencyBars(samples: trip?.samples ?? []).frame(height: 104)
                        HStack {
                            Text("inicio")
                            Spacer()
                            Text("\(trip?.measured.count ?? 0) pruebas")
                            Spacer()
                            Text("fin")
                        }.font(.caption2.monospaced()).foregroundStyle(Palette.muted)
                    }.padding(16).frame(maxWidth: .infinity).background(Palette.sage, in: .rect(cornerRadius: 20))

                    VStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(trip?.medianLatency.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? "—")
                                .font(.title.weight(.medium)).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                            Text("ms / mediana").font(.caption2.monospaced()).foregroundStyle(Palette.muted)
                        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white, in: .rect(cornerRadius: 20))
                        Button(action: openMap) {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "map").font(.title2)
                                Text("ver mapa").font(.caption.weight(.semibold))
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
                        }.background(Palette.sage.opacity(0.35), in: .rect(cornerRadius: 20))
                    }.frame(width: 112)
                }
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(trip?.suspectedZones ?? 0)").font(.title.weight(.semibold)).monospacedDigit()
                        Text("zonas sospechosas").font(.caption).foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(((trip?.distance ?? 0) / 1000).formatted(.number.precision(.fractionLength(2))) + " km")
                            .font(.title.weight(.medium)).monospacedDigit()
                        Text("distancia registrada").font(.caption).foregroundStyle(Palette.muted)
                    }
                }.padding(.horizontal, 4)

                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: recorder.isRecording ? "stop.fill" : "plus")
                        Text(recorder.isRecording ? "terminar recorrido" : "iniciar recorrido").font(.headline)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }.padding(20).foregroundStyle(.white)
                        .background(Palette.ink, in: .rect(cornerRadius: 20))
                }
                HStack(spacing: 8) {
                    Circle().fill(recorder.isRecording ? Palette.orange : Palette.muted).frame(width: 6, height: 6)
                    Text(recorder.status).font(.caption.monospaced())
                    Spacer()
                    if recorder.isRecording { Text("rec").font(.caption.monospaced().bold()) }
                }.foregroundStyle(Palette.muted)
                if trip == nil {
                    Text("sal a caminar. senda guardará el rastro de tu conexión, incluso cuando no puedas subirlo.")
                        .font(.footnote).foregroundStyle(Palette.muted).frame(maxWidth: .infinity, alignment: .leading)
                }
            }.padding(.horizontal, 24).padding(.bottom, 12)
        }.scrollIndicators(.hidden)
    }

    private func toggleRecording() {
        if recorder.isRecording { recorder.stop() }
        else { recorder.start(store: store) }
    }
}
