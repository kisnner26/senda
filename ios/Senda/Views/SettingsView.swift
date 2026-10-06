import SwiftUI

struct SettingsView: View {
    var store: TripStore
    var recorder: Recorder
    var live: LivePublisher
    @AppStorage("liveSharing") private var liveSharing = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("serverURL") private var server = ""
    @State private var token = CredentialStore.read()
    @State private var message = ""
    @State private var syncing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("tu rastro,\na salvo.").font(.largeTitle.bold())
                    Text("sin servidor, senda funciona en este iphone. conecta tu servidor para consultar los recorridos en la web.")
                        .font(.subheadline).foregroundStyle(Palette.muted)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("dirección del servidor").font(.caption.monospaced())
                        TextField("https://tu-servidor.com", text: $server)
                            .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .padding(16).background(.white, in: .rect(cornerRadius: 14))
                            .accessibilityLabel("dirección https del servidor")
                        Text("token privado").font(.caption.monospaced()).padding(.top, 8)
                        SecureField("token del servidor", text: $token)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .padding(16).background(.white, in: .rect(cornerRadius: 14))
                    }
                    Button(action: synchronize) {
                        HStack {
                            Text(syncing ? "sincronizando…" : "guardar y sincronizar").font(.headline)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }.padding(20).foregroundStyle(.white).background(Palette.ink, in: .rect(cornerRadius: 18))
                    }.disabled(syncing)
                    Text(message.isEmpty ? "\(store.trips.count { !$0.synced && $0.endedAt != nil }) recorridos pendientes" : message)
                        .font(.caption).foregroundStyle(Palette.muted).accessibilityAddTraits(.updatesFrequently)
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("compartir ubicación en vivo", isOn: $liveSharing).tint(Palette.ink)
                        Text(liveSharing ? (recorder.isRecording ? live.message : "se compartirá cuando inicies un recorrido") : "solo tú y quien tenga tu token pueden verla. al apagarla se retira de la web; sin conexión caduca en 90 s.")
                            .font(.caption).foregroundStyle(Palette.muted)
                        Button("solicitar ubicación precisa", systemImage: "location.viewfinder") {
                            Task { await recorder.requestPreciseLocation() }
                        }.font(.subheadline.bold()).padding(.vertical, 10)
                        Text(recorder.status).font(.caption).foregroundStyle(Palette.muted)
                        Text("compartir no aumenta la precisión del gps. el círculo del mapa muestra su margen de error.")
                            .font(.caption).foregroundStyle(Palette.muted)
                    }.padding(18).background(Palette.sage.opacity(0.5), in: .rect(cornerRadius: 18))
                    Divider()
                    Text("qué medimos").font(.headline)
                    Text("solicitudes https pequeñas a dos servicios independientes. medimos tiempo de respuesta y fallos, no intensidad de señal. más de 800 ms se considera lento. dos fallos seguidos indican una zona sospechosa.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                    Text("ios puede suspender las mediciones. un intervalo de más de 45 segundos se marca sin datos. el mapa necesita internet para cargar sus calles.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                }.padding(24)
            }.background(Palette.paper).navigationTitle("conexión").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("listo") { dismiss() } } }
        }.presentationDetents([.large])
    }

    private func synchronize() {
        syncing = true
        Task {
            defer { syncing = false }
            do {
                try CredentialStore.save(token)
                let count = try await store.sync(server: server.trimmingCharacters(in: .whitespacesAndNewlines), token: token)
                message = "\(count) recorridos sincronizados"
            } catch { message = error.localizedDescription }
        }
    }
}
