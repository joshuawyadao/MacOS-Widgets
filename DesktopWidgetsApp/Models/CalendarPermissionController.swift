import AppKit
import EventKit
import SwiftUI
import WidgetKit

@MainActor
final class CalendarPermissionController: ObservableObject {
    enum State: Equatable {
        case notDetermined
        case fullAccess
        case denied
    }

    @Published private(set) var state: State = .notDetermined
    @Published private(set) var isRequesting = false

    private let eventStore = EKEventStore()

    init() {
        refresh()
    }

    func refresh() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            state = .fullAccess
        case .notDetermined:
            state = .notDetermined
        default:
            state = .denied
        }
    }

    func refreshAndReloadWidget() {
        refresh()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetIdentifier.calendar.rawValue)
    }

    func requestAccess() {
        guard !isRequesting else { return }
        isRequesting = true
        Task {
            _ = try? await eventStore.requestFullAccessToEvents()
            isRequesting = false
            refreshAndReloadWidget()
        }
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
