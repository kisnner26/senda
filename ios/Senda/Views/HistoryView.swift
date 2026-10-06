import SwiftUI

struct HistoryView: View {
    var store: TripStore
    var select: (Trip) -> Void
    @State private var exportURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(store.trips.count) recorridos").font(.caption.monospaced()).foregroundStyle(Palette.muted)
                    Spacer()
                    if let exportURL {
                        ShareLink(item: exportURL) { Label("exportar", systemImage: "square.and.arrow.up").font(.caption) }
                    }
                }.padding(.vertical, 8)
                if store.trips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("tu primer rastro\nempieza afuera.").font(.title.bold())
                        Text("inicia un recorrido en la pestaña hoy. todo queda guardado en este iphone.")
                            .font(.subheadline).foregroundStyle(Palette.muted)
                    }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.sage, in: .rect(cornerRadius: 24))
                }
                ForEach(store.trips) { trip in
                    Button { select(trip) } label: {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                Text(trip.startedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                                    .font(.caption.monospaced())
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            HStack(alignment: .bottom) {
                                Text(trip.stability.map { ($0 * 100).formatted(.number.precision(.fractionLength(0))) + "%" } ?? "—")
                                    .font(.largeTitle.weight(.medium)).monospacedDigit()
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(trip.suspectedZones) zonas / \(trip.measured.count) pruebas")
                                    Text(trip.endedAt == nil ? "en curso" : trip.synced ? "sincronizado" : "guardado en iphone")
                                }.font(.caption).foregroundStyle(Palette.muted)
                            }
                        }.padding(20).background(Palette.sage, in: .rect(cornerRadius: 22))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 24)
        }.scrollIndicators(.hidden).task { exportURL = store.export() }
    }
}
