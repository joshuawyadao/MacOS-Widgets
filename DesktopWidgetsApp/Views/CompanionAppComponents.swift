import SwiftUI

struct AppPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(title: title, subtitle: subtitle)
                content()
            }
            .frame(maxWidth: 940, alignment: .leading)
            .padding(28)
        }
        .navigationTitle(title)
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.bold())

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.bold())

            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

struct HomeShortcutCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 42, height: 42)
                .background(WidgetTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ReadyWidgetCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 46, height: 46)
                .background(WidgetTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Ready")

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 106, alignment: .topLeading)
        .background(WidgetTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(WidgetTheme.accent.opacity(0.20), lineWidth: 1)
        }
    }
}

struct SetupStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(WidgetTheme.accent, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct WidgetGuideItem: Identifiable {
    let symbol: String
    let title: String
    let detail: String

    var id: String { title }
}

struct WidgetGuideSection: View {
    let title: String
    let subtitle: String
    let items: [WidgetGuideItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "\(title) options", subtitle: subtitle)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(items) { item in
                    CustomizationItem(
                        symbol: item.symbol,
                        title: item.title,
                        detail: item.detail
                    )
                }
            }
        }
    }
}

struct CustomizationItem: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct CalendarPermissionCard: View {
    @ObservedObject var controller: CalendarPermissionController

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: statusSymbol)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(statusTitle)
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(buttonTitle) {
                if controller.state == .denied {
                    controller.openPrivacySettings()
                } else {
                    controller.requestAccess()
                }
            }
            .disabled(controller.state == .fullAccess || controller.isRequesting)
        }
        .padding(14)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
    }

    private var statusSymbol: String {
        switch controller.state {
        case .notDetermined: "calendar.badge.plus"
        case .fullAccess: "checkmark.circle.fill"
        case .denied: "calendar.badge.exclamationmark"
        }
    }

    private var statusColor: Color {
        controller.state == .fullAccess ? .green : WidgetTheme.accent
    }

    private var statusTitle: String {
        switch controller.state {
        case .notDetermined: "Calendar event features are off"
        case .fullAccess: "Calendar access enabled"
        case .denied: "Calendar access is off"
        }
    }

    private var statusDetail: String {
        switch controller.state {
        case .notDetermined:
            "Enable access only if you want event counts, dots, or next-event timing. The widget never displays event titles or notes."
        case .fullAccess:
            "Calendar widgets can use event timing for private counts, dots, or a title-free next-event time."
        case .denied:
            "Open Privacy & Security → Calendars to allow optional event indicators or next-event timing."
        }
    }

    private var buttonTitle: String {
        if controller.isRequesting { return "Requesting…" }
        return switch controller.state {
        case .notDetermined: "Enable Access"
        case .fullAccess: "Enabled"
        case .denied: "Open Settings"
        }
    }
}

struct GlassBackgroundTip: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(WidgetTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("About the glass background")
                    .font(.headline)

                Text("With the Clear icon and widget style, macOS replaces widget backgrounds with Liquid Glass. Clear Light gives the softest appearance; place white widget text over a darker wallpaper area for the best readability.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}
