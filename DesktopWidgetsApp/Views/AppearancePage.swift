import SwiftUI

struct AppearancePage: View {
    @ObservedObject var typography: WidgetTypographyController

    var body: some View {
        AppPage(
            title: "Appearance",
            subtitle: "Preview one coordinated style, then apply it to all four widget types."
        ) {
            typographyGuide
            GlassBackgroundTip()
        }
    }

    private var typographyGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(
                title: "Appearance theme",
                subtitle: "Preview a coordinated style here, then apply the finished appearance to all widgets with one update request."
            )

            HStack(spacing: 12) {
                Menu {
                    ForEach(WidgetTypographyTheme.allCases) { theme in
                        Button {
                            typography.setGlobalTheme(theme)
                        } label: {
                            if typography.globalTheme == theme {
                                Label(
                                    "\(theme.displayName) — \(theme.detail)",
                                    systemImage: "checkmark"
                                )
                            } else {
                                Text("\(theme.displayName) — \(theme.detail)")
                            }
                        }
                    }
                } label: {
                    Label(
                        "\(typography.globalTheme.displayName) — \(typography.globalTheme.detail)",
                        systemImage: "textformat"
                    )
                }
                .frame(maxWidth: 280, alignment: .leading)

                Menu {
                    ForEach(WidgetTypographyCoverage.allCases) { coverage in
                        Button {
                            typography.setCoverage(coverage)
                        } label: {
                            if typography.coverage == coverage {
                                Label(coverage.displayName, systemImage: "checkmark")
                            } else {
                                Text(coverage.displayName)
                            }
                        }
                    }
                } label: {
                    Label(typography.coverage.displayName, systemImage: "character.cursor.ibeam")
                }
                .help(typography.coverage.detail)

                Spacer(minLength: 0)
                Button("Use System Style") {
                    typography.previewSystemStyle()
                }
                .disabled(typography.usesSystemDefaults)
            }

            TypographyPreviewGrid(
                resolutions: Dictionary(
                    uniqueKeysWithValues: WidgetTypographyTarget.allCases.map {
                        ($0, typography.resolution(for: $0))
                    }
                ),
                coverage: typography.coverage
            )

            Text(typography.coverage.detail)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("Widget overrides")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 10
            ) {
                ForEach(WidgetTypographyTarget.allCases) { target in
                    WidgetTypographyOverrideRow(
                        target: target,
                        selection: typography.override(for: target),
                        onSelect: { typography.setOverride($0, for: target) }
                    )
                }
            }

            Text("Time & Date can follow the global theme, use another theme, or preserve the separate date and time fonts configured on each placed copy.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Group {
                    if typography.hasPendingChanges {
                        Label(
                            "Preview only — apply when it looks right",
                            systemImage: "eye"
                        )
                    } else if let applicationFeedback = typography.applicationFeedback {
                        Label(applicationFeedback, systemImage: "checkmark.circle.fill")
                    } else {
                        Label("Desktop widgets match this preview", systemImage: "checkmark.circle")
                    }
                }
                .font(.caption)
                .foregroundStyle(typography.hasPendingChanges ? WidgetTheme.accent : .secondary)

                Spacer(minLength: 0)

                Button("Revert") {
                    typography.revertPreview()
                }
                .disabled(!typography.hasPendingChanges)

                Button("Apply Theme") {
                    typography.apply()
                }
                .buttonStyle(.borderedProminent)
                .tint(WidgetTheme.accent)
                .disabled(!typography.hasPendingChanges)
            }
        }
        .padding(18)
        .background(WidgetTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(WidgetTheme.accent.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct TypographyPreviewGrid: View {
    let resolutions: [WidgetTypographyTarget: WidgetTypographyResolution]
    let coverage: WidgetTypographyCoverage

    var body: some View {
        LazyVGrid(
            columns: WidgetTypographyTarget.allCases.map { _ in GridItem(.flexible(), spacing: 8) },
            spacing: 8
        ) {
            ForEach(WidgetTypographyTarget.allCases) { target in
                VStack(
                    alignment: .leading,
                    spacing: typographyStyle(for: target).verticalSpacing(7)
                ) {
                    Label(target.displayName, systemImage: target.symbolName)
                        .font(
                            typographyStyle(for: target).supportingFont(
                                size: 12,
                                weight: .semibold,
                                fallback: .caption.weight(.semibold)
                            )
                        )
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(
                            typographyStyle(for: target).supportingMinimumScaleFactor(0.7)
                        )
                        .padding(
                            .vertical,
                            typographyStyle(for: target).supportingTextVerticalPadding
                        )

                    Text(sampleText(for: target))
                        .font(
                            typographyStyle(for: target).displayFont(
                                size: 24,
                                weight: .black,
                                fallback: .custom("Noteworthy-Bold", size: 24)
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(
                            typographyStyle(for: target).displayMinimumScaleFactor(0.7)
                        )
                        .padding(
                            .vertical,
                            typographyStyle(for: target).displayTextVerticalPadding
                        )

                    Text(sampleDetail(for: target))
                        .font(
                            typographyStyle(for: target).supportingFont(
                                size: 10,
                                weight: .medium,
                                fallback: .system(size: 10, weight: .medium, design: .rounded)
                            )
                        )
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(
                            typographyStyle(for: target).supportingMinimumScaleFactor(0.7)
                        )
                        .padding(
                            .vertical,
                            typographyStyle(for: target).supportingTextVerticalPadding
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func sampleText(for target: WidgetTypographyTarget) -> String {
        switch target {
        case .timeAndDate: "09:09"
        case .weather: "72°"
        case .battery: "82%"
        case .calendar: "AUG 09"
        }
    }

    private func sampleDetail(for target: WidgetTypographyTarget) -> String {
        if resolutions[target] == .widgetFonts {
            return "Each copy's fonts"
        }
        return coverage == .allText ? "All text" : "Display text"
    }

    private func typographyStyle(for target: WidgetTypographyTarget) -> WidgetTypographyStyle {
        WidgetTypographyStyle(
            resolution: resolutions[target] ?? .theme(.system),
            coverage: coverage
        )
    }
}

private struct WidgetTypographyOverrideRow: View {
    let target: WidgetTypographyTarget
    let selection: WidgetTypographyOverride
    let onSelect: (WidgetTypographyOverride) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: target.symbolName)
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 22)

            Text(target.displayName)
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 4)

            Menu {
                ForEach(WidgetTypographyOverride.options(for: target)) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        if selection == option {
                            Label(option.displayName, systemImage: "checkmark")
                        } else {
                            Text(option.displayName)
                        }
                    }
                }
            } label: {
                Text(selection.displayName)
                    .lineLimit(1)
            }
            .accessibilityLabel("Typography for \(target.displayName)")
            .frame(maxWidth: 190, alignment: .trailing)
        }
        .padding(11)
        .background(.quaternary.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
    }
}
