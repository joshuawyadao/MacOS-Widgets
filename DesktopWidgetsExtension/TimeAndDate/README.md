# Time and Date Widget

Contains the configurable desktop clock: five adaptive layouts, five date formats, 12- and
24-hour time, independent date and time fonts, font specimen assets, and a removable clear
WidgetKit background.

The native editor uses example-based option labels, keeps date and time controls together, and
groups its fonts into **Clean & Classic** and **Handwritten** sections so choices are easier to
understand without knowing formatting tokens or font names in advance.

The native configuration intent transports stable string identifiers through concrete
`DynamicOptionsProvider` implementations, then resolves them into internal enums for rendering.
This avoids the macOS 26.5 AppEnum default-value regression while retaining native editor menus,
safe fallbacks, and independent settings for each placed widget.

`DesktopWidgetsTests` compiles the configuration source into a focused macOS test bundle and
checks every date/time formatter, every provider's stable IDs and default, invalid-ID fallbacks,
and two independently resolved configurations. Deterministic WidgetKit previews cover small,
medium, and large families plus an alternate side-by-side configuration; desktop editor and
restart persistence checks are listed in `docs/Time-And-Date-Widget.md`.
