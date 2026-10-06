enum Screen: String, CaseIterable, Identifiable {
    case overview, map, history
    var id: Self { self }
    var title: String {
        switch self { case .overview: "hoy"; case .map: "mapa"; case .history: "archivo" }
    }
    var symbol: String {
        switch self { case .overview: "circle.lefthalf.filled"; case .map: "map"; case .history: "arrow.counterclockwise" }
    }
}
