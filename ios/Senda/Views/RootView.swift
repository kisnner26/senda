import SwiftUI

struct RootView: View {
    @Bindable var store: TripStore
    @Bindable var recorder: Recorder
    @State private var screen = Screen.overview
    @State private var showSettings = false
    @State private var selectedTrip: UUID?
    @Environment(\.scenePhase) private var scenePhase
    private let demo = ProcessInfo.processInfo.arguments.contains("--demo")

    private var currentTrip: Trip? {
        store.trips.first { $0.id == (recorder.activeID ?? selectedTrip) } ?? store.trips.first
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("senda / \(screen == .overview ? "01" : screen == .map ? "02" : "03")")
                        .font(.caption.monospaced()).foregroundStyle(Palette.muted)
                    Text(screen == .overview ? "tu red,\nen el camino." : screen == .map ? "el territorio\nde tu conexión." : "cada vuelta\ndeja un rastro.")
                        .font(.largeTitle.weight(.bold)).tracking(-1.4).lineSpacing(-5)
                }
                Spacer(minLength: 8)
                Button("configuración", systemImage: "slider.horizontal.3") { showSettings = true }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44)
                    .background(.white.opacity(0.6), in: .circle)
            }.padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 16)

            if demo {
                Text("vista de demostración · datos ficticios")
                    .font(.caption.monospaced()).padding(8).frame(maxWidth: .infinity)
                    .background(Palette.orange.opacity(0.15))
            }
            if let error = store.error {
                Text(error).font(.caption).foregroundStyle(Palette.rust).padding(.horizontal, 24)
            }

            switch screen {
            case .overview:
                DashboardView(trip: currentTrip, recorder: recorder, store: store) { screen = .map }
            case .map:
                RouteMapView(trip: TripSelection.mapTrip(in: store.trips, activeID: recorder.activeID, selectedID: selectedTrip),
                    isRecording: recorder.isRecording, locationStatus: recorder.status)
            case .history:
                HistoryView(store: store) { trip in selectedTrip = trip.id; screen = .map }
            }

            HStack(spacing: 8) {
                ForEach(Screen.allCases) { item in
                    Button { screen = item } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.symbol)
                            Text(item.title).font(.subheadline.weight(screen == item ? .bold : .regular))
                        }.frame(maxWidth: .infinity).frame(minHeight: 48)
                            .foregroundStyle(screen == item ? Palette.ink : Palette.muted)
                            .background(screen == item ? Color.white : .clear, in: .capsule)
                    }.accessibilityAddTraits(screen == item ? .isSelected : [])
                }
            }.padding(8).background(Palette.ink.opacity(0.05), in: .capsule)
                .padding(.horizontal, 24).padding(.vertical, 12)
        }
        .foregroundStyle(Palette.ink)
        .background(screen == .map ? Palette.sage : Palette.paper)
        .sheet(isPresented: $showSettings) { SettingsView(store: store) }
        .task {
            recorder.onNetworkAvailable = { Task { await synchronizeIfConfigured() } }
            await synchronizeIfConfigured()
        }
        .onChange(of: recorder.isRecording) { _, active in
            if !active { Task { await synchronizeIfConfigured() } }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await synchronizeIfConfigured() } }
        }
    }

    private func synchronizeIfConfigured() async {
        guard !demo, store.trips.contains(where: { !$0.synced && $0.endedAt != nil }),
              let server = UserDefaults.standard.string(forKey: "serverURL"), !server.isEmpty else { return }
        let token = CredentialStore.read()
        guard !token.isEmpty else { return }
        do { _ = try await store.sync(server: server, token: token) }
        catch { store.error = "sincronización pendiente: \(error.localizedDescription)" }
    }
}
