import SwiftUI

struct WidgetGuidePage: View {
    let widget: CompanionAppDestination
    @Binding var destination: CompanionAppDestination?
    @ObservedObject var calendarPermission: CalendarPermissionController

    var body: some View {
        AppPage(title: widget.title, subtitle: widgetSubtitle) {
            editWidgetCard
            WidgetGuideSection(
                title: widget.title,
                subtitle: widgetGuideSubtitle,
                items: widgetGuideItems
            )

            if widget == .weather {
                weatherDetailLimitsTip
            }

            if widget == .calendar {
                CalendarPermissionCard(controller: calendarPermission)
            }

            Button {
                destination = .appearance
            } label: {
                Label("Customize \(widget.title) appearance", systemImage: "paintbrush")
            }
        }
    }

    private var widgetSubtitle: String {
        switch widget {
        case .timeAndDate:
            "Arrange the clock, choose date and time formats, and optionally add a second time zone."
        case .weather:
            "Choose a city, forecast view, units, and the weather details that matter to you."
        case .battery:
            "See this Mac's charge and power state with optional runtime and battery-health details."
        case .calendar:
            "Choose a focused Day, Week, or Month view with optional private event timing."
        default:
            ""
        }
    }

    private var editWidgetCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .font(.title2)
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text("Edit a placed \(widget.title) widget")
                    .font(.headline)
                Text("Control-click the widget on your desktop, choose Edit \(widget.title), then adjust the options for that copy.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(WidgetTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(WidgetTheme.accent.opacity(0.18), lineWidth: 1)
        }
    }

    private var widgetGuideSubtitle: String {
        switch widget {
        case .timeAndDate:
            "Every placed copy keeps its own layout and format choices."
        case .weather:
            "Forecast content adapts to the widget's size and selected view."
        case .battery:
            "All readings stay local to this Mac and require no account."
        case .calendar:
            "Event features use timing only and never display event titles or notes."
        default:
            ""
        }
    }

    private var widgetGuideItems: [WidgetGuideItem] {
        switch widget {
        case .timeAndDate:
            [
                WidgetGuideItem(symbol: "rectangle.3.group", title: "View", detail: "Classic, compact, centered, time first, or side by side."),
                WidgetGuideItem(symbol: "calendar", title: "Date", detail: "Choose a word-based, month-first, day-first, or ISO date."),
                WidgetGuideItem(symbol: "clock", title: "Time", detail: "Use a 12-hour or 24-hour clock; AM/PM adapts automatically."),
                WidgetGuideItem(symbol: "globe", title: "Second Clock", detail: "Add a world time zone and an optional label such as Home or Family."),
                WidgetGuideItem(symbol: "textformat", title: "Appearance", detail: "Follow the app theme or preserve separate date and time fonts for each copy."),
            ]
        case .weather:
            [
                WidgetGuideItem(symbol: "building.2", title: "City", detail: "Search for a city and choose the exact region and country."),
                WidgetGuideItem(symbol: "calendar.day.timeline.leading", title: "View", detail: "Switch between the week, today, and the next six hours."),
                WidgetGuideItem(symbol: "square.stack.3d.up", title: "Details", detail: "Choose presets for comfort, rain, outdoor conditions, UV, sunrise, and sunset."),
                WidgetGuideItem(symbol: "thermometer.medium", title: "Units", detail: "Follow this Mac or choose Fahrenheit or Celsius."),
            ]
        case .battery:
            [
                WidgetGuideItem(symbol: "battery.75percent", title: "Source", detail: "Reads this Mac's internal battery through the local system API."),
                WidgetGuideItem(symbol: "rectangle.3.group", title: "Size", detail: "Small emphasizes charge; Medium and Large progressively add details."),
                WidgetGuideItem(symbol: "timer", title: "Details", detail: "Toggle Power, Status, Estimate, Updated, Health, and Cycles for each copy."),
                WidgetGuideItem(symbol: "bolt.fill", title: "Status", detail: "Distinguishes charging, discharging, AC power, calculating, and no battery."),
            ]
        case .calendar:
            [
                WidgetGuideItem(symbol: "calendar", title: "Source", detail: "Uses this Mac's calendar, locale, time zone, and first-weekday preference."),
                WidgetGuideItem(symbol: "rectangle.3.group", title: "View", detail: "Automatic chooses Day, Week, or Month by size; each copy can override it."),
                WidgetGuideItem(symbol: "circle.grid.2x2.fill", title: "Event Marks", detail: "Optional counts and dots show busy days without revealing event text."),
                WidgetGuideItem(symbol: "calendar.badge.clock", title: "Next Event", detail: "Optionally show only the next timed event's start time, never its title."),
                WidgetGuideItem(symbol: "arrow.left.arrow.right", title: "Navigation", detail: "Month view can move backward, forward, or return to the current month."),
            ]
        default:
            []
        }
    }

    private var weatherDetailLimitsTip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checklist.checked")
                .font(.title3)
                .foregroundStyle(WidgetTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Weather detail presets")
                    .font(.headline)

                Text("Day view fits 2 details on Small, 3 on Medium, and 5 on Large. Narrow Week and Hour columns show 1 detail on Small or Medium and 2 on Large so labels stay readable. Larger presets keep the first details that fit and show a “Showing X of Y” notice.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}
