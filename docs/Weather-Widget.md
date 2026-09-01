# Weather Widget

The Weather widget recreates the supplied reference's quiet visual rhythm: a monospaced city label, evenly spaced forecast columns, simple condition symbols, rounded white type, and no app-drawn card behind the content. The wallpaper remains outside the widget; macOS may still place its own Liquid Glass surface over a clear widget.

## Add and customize it

1. Open `DesktopWidgets.xcodeproj`, select **My Mac**, and run the `DesktopWidgets` scheme once.
2. Remove the existing Weather widget before adding build 15. Build 15 has a new WidgetKit identity, so the old instance cannot migrate and may appear as a blank macOS placeholder. An editor titled **Location** or one with separate **Search City** and **Matching City** rows also belongs to an older widget; the current editor exposes one searchable **City** row.
3. Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and add **Weather**.
4. Control-click the placed widget and choose **Edit Weather**.
5. Configure these settings for that widget instance:

| Setting | Behavior |
| --- | --- |
| City | Open **City**, type at least two letters, and choose the exact place from the matching list. Up to 20 results show the city with its state/region and country, so same-named cities remain distinct. The selected result supplies its exact coordinate and time zone to the forecast service. Portland, Oregon is the default. |
| Forecast View | **Week** shows seven days on medium and large widgets; a small widget focuses on today. **Day** shows current conditions and today's high/low. **Hour** shows the next six hours, or three on a small widget. Large Week and Hour views add a current-conditions hero, high/low, and selected details above the forecast strip. |
| Temperature Units | **Automatic** follows the Mac's regional temperature and wind conventions. Explicit Fahrenheit uses mph; explicit Celsius uses km/h. |
| Details Preset | Apply several details with one selection: **Minimal** (Temperature), **Simple** (Temperature + Condition), **Rain** (Temperature + Rain chance), **Comfort** (Temperature + Feels like + Humidity), **Sun** (Temperature + Sunrise + Sunset + UV), **Outdoor** (Temperature + Rain + Wind + UV), **Detailed** (Temperature + Condition + Feels like + Humidity), or **Full** (all nine details). |

Day view can show the first 2 details on Small, 3 on Medium, or 6 on Large. The narrower Week and Hour columns show 1 detail on Small and Medium or 2 on Large. Each family has its own header, icon, temperature, column-gap, and vertical-spacing metrics. If a preset contains more than that presentation can display, the widget keeps the first details that fit and displays a compact **Showing X of Y · Size limit N** notice. Minimal is the defensive fallback if macOS restores an empty or invalid configuration.

Each placed widget owns its configuration. One instance can show Portland's week in Fahrenheit while another shows Tokyo's next six hours in Celsius.

## Data source and refresh behavior

This personal, subscription-free build uses [Open-Meteo's Forecast API](https://open-meteo.com/en/docs) and [Geocoding API](https://open-meteo.com/en/docs/geocoding-api). The searchable City list queries Open-Meteo after at least two characters, requests up to 20 matches, removes exact duplicates, and stores the selected result's resolved name, coordinate, and time zone in the widget configuration. Each forecast request sends that coordinate to Open-Meteo and requests current conditions, seven daily forecasts, and the next 24 hourly forecasts. The provider-neutral model includes temperature, apparent temperature, relative humidity, precipitation probability, wind speed, UV index, sunrise, sunset, and WMO weather condition codes. Older cached snapshots remain readable; newly unavailable metrics simply display as unavailable or yield to the next detail that fits.

The free endpoint is keyless and limited to noncommercial use under [Open-Meteo's current terms](https://open-meteo.com/en/terms). Forecast data is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), so the widget displays a linked **Open-Meteo** credit next to the city. Values are normalized into the app's provider-neutral model and rounded for display. A commercial release must use an appropriately licensed provider or a paid Open-Meteo endpoint and must not embed an API key directly in a public client.

WidgetKit receives several future hourly entries from one forecast response and asks for fresh data approximately hourly. A matching city-and-unit snapshot no older than 15 minutes is reused before opening a network connection, and simultaneous identical requests share one in-flight operation. Completed requests are not retained in memory. Forecast times use Unix timestamps so repeated local hours around daylight-saving transitions remain unambiguous. The system owns the actual schedule and may delay or coalesce refreshes. If a refresh fails, the widget shows the last successful forecast with a visible last-updated label and retries later. If the city has never loaded, it shows a focused error with editing guidance.

Each rendered entry resolves its presentation, typography, family metrics, localized forecast titles, and combined VoiceOver labels once before SwiftUI constructs the forecast columns. Batch title formatting reuses one formatter for the visible day or hour sequence. This render preparation does not change the hourly network-refresh policy or the stale-cache fallback described above.

## Privacy

- macOS owns the configuration interface. The extension sends the text typed into the City search to Open-Meteo's geocoding endpoint and the selected result's coordinate to its forecast endpoint. Open-Meteo's geocoding data is based on [GeoNames](https://www.geonames.org/).
- Open-Meteo states that service logs can contain IP addresses, request URLs, and coordinates for troubleshooting and may retain them for up to 90 days; see its [Terms & Privacy](https://open-meteo.com/en/terms).
- To reduce requests, the extension reuses a matching cached city/unit forecast for 15 minutes and stores up to 12 normalized forecasts for no more than 24 hours as failure fallbacks. Cache filenames use hashes. The selected city and coordinate also live in that widget instance's macOS-managed configuration. These are user-selected places, not device-location or movement data. The widget does not request precise device location, use analytics, or commit cities to source control.
- No WeatherKit entitlement, Apple Developer Program membership, API key, account, or Location Services permission is required for this implementation.

## Appearance and accessibility

- Weather uses the shared compact/standard/expanded family density and widget surface. Its city header, forecast symbols, and required provider attribution remain domain-specific.
- The companion app's global or Weather-specific typography theme styles the city header and hero current temperature in Display Text mode. All Text extends it to forecast strips, detail values, status text, and provider attribution; Display Text remains the safer choice when a decorative font makes compact forecasts harder to scan.
- The widget declares a clear, removable WidgetKit container exactly like Time & Date. With macOS's Clear icon and widget style, the system may replace that background with Liquid Glass, tint, or blur; WidgetKit does not provide an API to remove the system-owned surface.
- White text and multicolor SF Symbols follow the reference. Every forecast column combines its day or hour, condition, and selected values into one VoiceOver label so color and symbols are not the only source of meaning.
- Temperatures render as one compact text run so WidgetKit cannot truncate the degree value and unit independently. Small Today reserves a bounded temperature column and uses a sequence of complete-text fallback sizes instead of an ellipsis-producing scale. High/low values remain stacked, and VoiceOver announces the complete unit.
- The small Week layout deliberately becomes a readable Today layout instead of compressing seven columns beyond legibility. Medium keeps all seven days with smaller forecast type and symbols plus wider inter-column gaps because Medium and Large share the same horizontal canvas. Large gives the full location and attribution separate header rows, then divides the remaining height between the enlarged current summary and a forecast section whose weekday, icon, and temperature stay grouped with fixed spacing.
- Bright wallpapers can reduce white-text contrast. Clear Light generally provides the softest glass appearance, while a darker wallpaper region improves readability.

## Signing and networking

The widget extension enables the macOS App Sandbox **Outgoing Connections (Client)** entitlement because it contacts Open-Meteo over HTTPS.

The searchable City parameter is a custom App Intent entity. Although the editor can display and save a city under ad-hoc **Sign to Run Locally** signing, macOS cannot register or restore that entity without a development Team ID. The timeline then receives a nil city and defensively falls back to Portland. Both the host app and extension therefore use automatic Apple Development signing through `Config/Signing.xcconfig`; the actual free Personal Team ID lives only in ignored `Local.xcconfig`.

Complete the one-time setup in the root README, then run the app again. A correctly signed built extension reports the Personal Team instead of `TeamIdentifier=not set` when inspected with `codesign -dvvv`. No paid membership is required for this local workflow. The unsigned Release build used by `Scripts/verify-widgets.sh` remains intentionally independent of developer accounts.

The shared Xcode Run scheme executes `Scripts/refresh-widget-runtime.sh` before launching the app. It finds registrations with this extension's bundle identifier, unregisters only stale copies inside Xcode's DerivedData tree, stops the existing Desktop Widgets extension process, registers the newly built extension, and restarts the current user's widget daemon. This prevents an existing desktop widget from remaining attached to another worktree's older executable or descriptor. It does not delete build products, widget configuration, or cache data, and it preserves matching installed copies outside DerivedData. After any intentional widget-kind change, remove the retired desktop instance once and add the current widget from the gallery.

Apple WeatherKit was not selected because Apple's [WeatherKit account setup](https://developer.apple.com/help/account/services/weatherkit/) requires Apple Developer Program membership and a WeatherKit-enabled App ID. If the project later adopts paid provisioning, keep the provider-neutral forecast model, add the required WeatherKit entitlement and Apple Weather attribution, and replace the Open-Meteo service at the provider boundary.

## Desktop acceptance checklist

`./Scripts/verify-widgets.sh` covers stable configuration defaults, searchable-city entity presentation and identifier restoration, coordinate delivery, multiple duplicate-name results, the 20-result cap, family-specific layout metrics, all family/view/preset presentation combinations, accessible forecast titles, nine-detail limits and notices, loaded/stale/failure states, forecast-city scheduling, request construction for apparent temperature, UV, sunrise, and sunset, response decoding, WMO mapping, unit formatting, cached forecast round trips, representative SwiftUI rendering, the Release extension bundle, and its App Intent metadata.

Those automated contracts are consumed by the SwiftUI view, and render smoke tests confirm representative long-location, stale, and failure states can produce pixels at real widget-family sizes. The remaining checklist is intentionally limited to macOS-owned integration and visual quality:

- [ ] Add one Weather widget and confirm macOS exposes City, Forecast View, Temperature Units, and Details Preset editor rows, with no raw encoded identifier visible.
- [ ] Open City, type at least two letters, confirm several region/country-labeled results appear for a common name, choose one, and verify it persists and refreshes the forecast.
- [ ] Add Small, Medium, and Large copies and confirm Small always shows the full temperature and unit, Medium forecast columns have comfortable visible gaps, and Large shows the full location while keeping each forecast column evenly grouped within the available height.
- [ ] Compare Medium and Large Week or Hour widgets and confirm Large shows the expanded current-conditions dashboard above its forecast strip.
- [ ] Select Comfort, Sun, and Outdoor presets and confirm feels-like temperature, UV, sunrise, and sunset are readable and unavailable values fail gracefully.
- [ ] Disconnect networking after one successful load and confirm the extension's sandbox allows the cached forecast to remain visible on the desktop.
- [ ] Verify the Open-Meteo link is visible and opens the provider site.
- [ ] Compare Clear Light, Clear Dark, and Tinted appearances and confirm the content stays readable.
- [ ] Change the global theme and Weather override in the companion app, then confirm the location and hero temperature update without compressing forecast details.
- [ ] Use VoiceOver once to confirm the system traverses each combined forecast label in a sensible order.
