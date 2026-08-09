struct WidgetStatus: Identifiable {
    let name: String
    let symbol: String
    let status: String
    let isAvailable: Bool

    var id: String { name }
}
