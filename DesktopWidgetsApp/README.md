# DesktopWidgetsApp

Host macOS app for widget onboarding, settings, permissions, and shared configuration.

The initial screen presents all four widgets, explains their setup and interaction patterns, and owns
Calendar's optional full-access permission request. Calendar permission is requested only after the
user selects **Enable Access**; the extension then reads event timing for counts, dots, and an
optional next-event start time without displaying titles or notes.
