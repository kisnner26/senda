import SwiftUI

struct LatencyBars: View {
    var samples: [Measurement]

    private var buckets: [Double?] {
        guard !samples.isEmpty else { return Array(repeating: nil, count: 7) }
        return (0..<7).map { bucket in
            let start = bucket * samples.count / 7
            let end = (bucket + 1) * samples.count / 7
            let values = samples[start..<end].compactMap(\.latency)
            return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let ceiling = max(200, buckets.compactMap { $0 }.max() ?? 200)
            HStack(alignment: .bottom, spacing: 9) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { index, value in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(index == 3 ? Palette.ink : Palette.ink.opacity(0.13))
                        .frame(height: value.map { max(10, min(geometry.size.height, $0 / ceiling * geometry.size.height)) } ?? 5)
                        .overlay {
                            if index != 3 {
                                Canvas { context, size in
                                    var path = Path()
                                    stride(from: -size.height, to: size.width, by: 10).forEach { x in
                                        path.move(to: .init(x: x, y: size.height))
                                        path.addLine(to: .init(x: x + size.height, y: 0))
                                    }
                                    context.stroke(path, with: .color(Palette.sage), lineWidth: 5)
                                }.clipShape(.rect(cornerRadius: 8))
                            }
                        }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .accessibilityLabel("tiempo de respuesta a lo largo del recorrido; los huecos representan ausencia de mediciones válidas")
    }
}
