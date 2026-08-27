# Calendar Widget

This module contains Calendar App Intent configuration, locale-aware Day/Week/Month presentations, EventKit interval-to-count and next-time normalization, persisted Month navigation actions, adaptive timeline policy, responsive metrics, and the SwiftUI Calendar widget.

Automatic mode maps Small to Day, Medium to Week, and Large to Month, while every copy can override the view. Event indicators and next-event timing are opt-in and reduce EventKit objects to per-day counts plus an optional timed-event start; titles, notes, locations, attendees, and calendar names never enter the widget model. See `docs/Calendar-Widget.md` for permission setup, behavior, privacy, verification, and desktop acceptance guidance.
