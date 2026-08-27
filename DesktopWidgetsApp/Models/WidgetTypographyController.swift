import SwiftUI
import WidgetKit

@MainActor
final class WidgetTypographyController: ObservableObject {
    @Published private var selection: WidgetTypographySelection
    @Published private(set) var applicationFeedback: String?

    private let applier: WidgetTypographyApplier
    private var appliedSelection: WidgetTypographySelection

    init(
        store: WidgetTypographyStore = .live,
        requestReload: @escaping () -> Void = {
            WidgetCenter.shared.reloadAllTimelines()
        }
    ) {
        self.applier = WidgetTypographyApplier(
            store: store,
            requestReload: requestReload
        )
        let storedSelection = WidgetTypographySelection(store: store)
        self.selection = storedSelection
        self.appliedSelection = storedSelection
    }

    var globalTheme: WidgetTypographyTheme {
        selection.globalTheme
    }

    var coverage: WidgetTypographyCoverage {
        selection.coverage
    }

    var usesSystemDefaults: Bool {
        selection.usesSystemDefaults
    }

    var hasPendingChanges: Bool {
        selection != appliedSelection
    }

    func override(for target: WidgetTypographyTarget) -> WidgetTypographyOverride {
        selection.override(for: target)
    }

    func resolution(for target: WidgetTypographyTarget) -> WidgetTypographyResolution {
        selection.resolution(for: target)
    }

    func setGlobalTheme(_ theme: WidgetTypographyTheme) {
        selection.globalTheme = theme
        applicationFeedback = nil
    }

    func setCoverage(_ coverage: WidgetTypographyCoverage) {
        selection.coverage = coverage
        applicationFeedback = nil
    }

    func setOverride(
        _ override: WidgetTypographyOverride,
        for target: WidgetTypographyTarget
    ) {
        selection.setOverride(override, for: target)
        applicationFeedback = nil
    }

    func previewSystemStyle() {
        selection = .systemDefault
        applicationFeedback = nil
    }

    func revertPreview() {
        selection = appliedSelection
        applicationFeedback = nil
    }

    func apply() {
        guard hasPendingChanges else { return }
        applier.apply(selection)
        appliedSelection = selection
        applicationFeedback = "Theme applied — macOS is updating the widgets"
    }
}
