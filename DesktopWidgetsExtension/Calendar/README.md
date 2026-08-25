# Calendar Widget

This module contains the locale-aware month presentation, persisted WidgetKit navigation actions, daily timeline policy, responsive metrics, and SwiftUI Calendar widget.

The widget intentionally does not request EventKit access or display private event data. It follows the Mac's calendar, first weekday, locale, and time zone; shows six stable rows; highlights today; and lets the user browse months with native interactive-widget buttons. See `docs/Calendar-Widget.md` for behavior, privacy, verification, and desktop acceptance guidance.
