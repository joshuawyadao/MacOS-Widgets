import SwiftUI
import WidgetKit

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

    static let fullColorShadowOpacity = 0.46
    static let fullColorShadowRadius: CGFloat = 1.5
    static let fullColorShadowY: CGFloat = 1
    static let secondaryOpacity = 0.76
    static let detailCardOpacity = 0.10
    static let detailCardCornerRadius: CGFloat = 12
}

enum WidgetInformationDensity: Equatable, Sendable {
    case compact
    case standard
    case expanded

    init(family: WidgetFamily) {
        switch family {
        case .systemSmall:
            self = .compact
        case .systemLarge:
            self = .expanded
        default:
            self = .standard
        }
    }
}

struct WidgetChromeMetrics: Equatable, Sendable {
    let statusFontSize: CGFloat
    let statusIconSize: CGFloat
    let statusSpacing: CGFloat
    let sectionSpacing: CGFloat

    init(family: WidgetFamily) {
        switch WidgetInformationDensity(family: family) {
        case .compact:
            statusFontSize = 8.5
            statusIconSize = 9
            statusSpacing = 3
            sectionSpacing = 5
        case .standard:
            statusFontSize = 9
            statusIconSize = 10
            statusSpacing = 4
            sectionSpacing = 10
        case .expanded:
            statusFontSize = 10
            statusIconSize = 11
            statusSpacing = 5
            sectionSpacing = 10
        }
    }
}

enum WidgetSurfaceTreatment: Equatable, Sendable {
    case wallpaperContrast
    case systemTint

    init(renderingMode: WidgetRenderingMode) {
        self = renderingMode == .fullColor ? .wallpaperContrast : .systemTint
    }

    var usesContrastShadow: Bool {
        self == .wallpaperContrast
    }
}

struct WidgetStatusLine: View {
    @Environment(\.widgetFamily) private var family

    let text: String
    let systemImage: String
    var accessibilityText: String?

    private var metrics: WidgetChromeMetrics {
        WidgetChromeMetrics(family: family)
    }

    var body: some View {
        HStack(spacing: metrics.statusSpacing) {
            Image(systemName: systemImage)
                .font(.system(size: metrics.statusIconSize, weight: .semibold))
            Text(text)
        }
        .font(.system(size: metrics.statusFontSize, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .opacity(WidgetTheme.secondaryOpacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText ?? text)
    }
}

struct WidgetStatusBadge: View {
    @Environment(\.widgetFamily) private var family

    let systemImage: String
    let accessibilityText: String

    private var metrics: WidgetChromeMetrics {
        WidgetChromeMetrics(family: family)
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: metrics.statusIconSize, weight: .bold))
            .accessibilityLabel(accessibilityText)
    }
}

private struct WidgetSurfaceModifier: ViewModifier {
    let renderingMode: WidgetRenderingMode

    private var treatment: WidgetSurfaceTreatment {
        WidgetSurfaceTreatment(renderingMode: renderingMode)
    }

    func body(content: Content) -> some View {
        content
            .foregroundStyle(treatment == .wallpaperContrast ? Color.white : Color.primary)
            .shadow(
                color: treatment.usesContrastShadow
                    ? .black.opacity(WidgetTheme.fullColorShadowOpacity)
                    : .clear,
                radius: WidgetTheme.fullColorShadowRadius,
                x: 0,
                y: WidgetTheme.fullColorShadowY
            )
            .containerBackground(for: .widget) {
                Color.clear
            }
    }
}

extension View {
    func widgetSurface(renderingMode: WidgetRenderingMode) -> some View {
        modifier(WidgetSurfaceModifier(renderingMode: renderingMode))
    }
}
