import SwiftUI

enum WidgetTheme {
    static let accent = Color(red: 0.47, green: 0.36, blue: 0.86)
    static let background = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.95, blue: 1.00),
            Color(red: 0.88, green: 0.91, blue: 1.00),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
