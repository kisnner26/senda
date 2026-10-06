import SwiftUI

struct StabilityDial: View {
    var value: Double?
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize = 62

    var body: some View {
        ZStack {
            Circle().stroke(.white, lineWidth: 46).padding(24)
            ForEach(0..<12) { tick in
                Capsule().fill(Palette.ink.opacity(0.18)).frame(width: 2, height: 10)
                    .offset(y: -124).rotationEffect(.degrees(Double(tick) * 30))
            }
            Circle().fill(Palette.orange).frame(width: 13, height: 13)
                .offset(y: -124).rotationEffect(.degrees((value ?? 0) * 360))
            VStack(spacing: 0) {
                Text(value.map { ($0 * 100).formatted(.number.precision(.fractionLength(0))) + "%" } ?? "—")
                    .font(.system(size: numberSize, weight: .medium)).tracking(-3).monospacedDigit()
                    .minimumScaleFactor(0.5).lineLimit(1)
                Text(value == nil ? "sin mediciones" : "con internet")
                    .font(.caption).foregroundStyle(Palette.muted)
            }.padding(56)
        }
        .frame(width: 286, height: 286)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.map { "conexión disponible en \(($0 * 100).formatted(.number.precision(.fractionLength(0)))) por ciento de las pruebas" } ?? "todavía no hay mediciones")
    }
}
