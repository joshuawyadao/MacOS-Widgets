# Weather Widget

The Weather widget recreates the supplied reference's quiet visual rhythm: a monospaced city label, evenly spaced forecast columns, simple condition symbols, rounded white type, and no app-drawn card behind the content. The wallpaper remains outside the widget; macOS may still place its own Liquid Glass surface over a clear widget.

## Add and customize it

1. Open `DesktopWidgets.xcodeproj`, select **My Mac**, and run the `DesktopWidgets` scheme once.
2. Remove the existing Weather widget before adding build 14. An editor titled **Location** with a red pin is the retired placemark widget; the current editor exposes separate **Search City** and **Matching City** rows.
3. Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and add **Weather**.
4. Control-click the placed widget and choose **Edit Weather**.
5. Configure these settings for that widget instance:

| Setting | Behavior |
| --- | --- |
| Search City + Matching City | Type at least two letters in **Search City**, then open **Matching City** and choose the exact result. Up to 20 results use full city, state, and country labels, so same-named cities remain distinct instead of collapsing into one row. The selected result supplies its exact coordinate and time zone to the forecast service. Portland, Oregon is the default. |
| Forecast View | **Week** shows seven days on medium and large widgets; a small widget focuses on today. **Day** shows current conditions and today's high/low. **Hour** shows the next six hours, or three on a small widget. Large Week and Hour views add a current-conditions hero, high/low, and selected details above the forecast strip. |
| Temperature Units | **Automatic** follows the Mac's regional temperature and wind conventions. Explicit Fahrenheit uses mph; explicit Celsius uses km/h. |
| Details Preset | Apply several details with one selection: **Minimal** (Temperature), **Simple** (Temperature + Condition), **Rain** (Temperature + Rain chance), **Comfort** (Temperature + Humidity), **Detailed** (Temperature + Condition + Humidity), or **Full** (all five details). |

Day view can show the first 2 details on Small, 3 on Medium, or all 5 on Large. The narrower Week and Hour columns show 1 detail on Small and Medium or 2 on Large. Each family has its own header, icon, temperature, column-gap, and vertical-spacing metrics. If a preset contains more than that presentation can display, the widget keeps the first details that fit and displays a compact **Showing X of Y · Size limit N** notice. Minimal is the defensive fallback if macOS restores an empty or invalid configuration.

Each placed widget owns its configuration. One instance can show Portland's week in Fahrenheit while another shows Tokyo's next six hours in Celsius.

## Data source and refresh behavior

This personal, subscription-free build uses [Open-Meteo's Forecast API](https://open-meteo.com/en/docs) and [Geocoding API](https://open-meteo.com/en/docs/geocoding-api). The dependent Matching City list searches Open-Meteo after at least two characters, requests up to 20 matches, removes exact duplicates, and stores the selected result's resolved name, coordinate, and time zone in the widget configuration. Each refresh sends that coordinate to Open-Meteo and requests current conditions, seven daily forecasts, and hourly forecasts. The normalized model includes temperature, relative humidity, precipitation probability, wind speed, and WMO weather condition codes.

The free endpoint is keyless and limited to noncommercial use under [Open-Meteo's current terms](https://open-meteo.com/en/terms). Forecast data is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), so the widget displays a linked **Open-Meteo** credit next to the city. Values are normalized into the app's provider-neutral model and rounded for display. A commercial release must use an appropriately licensed provider or a paid Open-Meteo endpoint and must not embed an API key directly in a public client.

WidgetKit receives several future hourly entries from one forecast response and asks for fresh data approximately hourly. Forecast times use Unix timestamps so repeated local hours around daylight-saving transitions remain unambiguous. The system owns the actual schedule and may delay or coalesce refreshes. If a refresh fails, the widget shows the last successful forecast with a visible last-updated label and retries later. If the city has never loaded, it shows a focused error with editing guidance.

## Privacy

- macOS owns the configuration interface. The extension sends the typed Search City text to Open-Meteo's geocoding endpoint and the selected result's coordinate to its forecast endpoint. Open-Meteo's geocoding data is based on [GeoNames](https://www.geonames.org/).
- Open-Meteo states that service logs can contain IP addresses, request URLs, and coordinates for troubleshooting and may retain them for up to 90 days; see its [Terms & Privacy](https://open-meteo.com/en/terms).
- To reduce requests, the extension stores up to 12 recent normalized city/unit forecasts for no more than 24 hours. Cache filenames use hashes. The selected city and coordinate also live in that widget instance's macOS-managed configuration. These are user-selected places, not device-location or movement data. The widget does not request precise device location, use analytics, or commit cities to source control.
- No WeatherKit entitlement, Apple Developer Program membership, API key, account, or Location Services permission is required for this implementation.

## Appearance and accessibility

- The widget declares a clear, removable WidgetKit container exactly like Time & Date. With macOS's Clear icon and widget style, the system may replace that background with Liquid Glass, tint, or blur; WidgetKit does not provide an API to remove the system-owned surface.
- White text and multicolor SF Symbols follow the reference. Every forecast column combines its day or hour, condition, and selected values into one VoiceOver label so color and symbols are not the only source of meaning.
- Temperatures render as one compact, scalable text run so WidgetKit cannot truncate the degree value and unit independently. VoiceOver still announces the complete unit.
- The small Week layout deliberately becomes a readable Today layout instead of compressing seven columns beyond legibility.
- Bright wallpapers can reduce white-text contrast. Clear Light generally provides the softest glass appearance, while a darker wallpaper region improves readability.

## Signing and networking

The widget extension enables the macOS App Sandbox **Outgoing Connections (Client)** entitlement because it contacts Open-Meteo over HTTPS. This entitlement works with the existing teamless **Sign to Run Locally** setup.

Apple WeatherKit was not selected because Apple's [WeatherKit account setup](https://developer.apple.com/help/account/services/weatherkit/) requires Apple Developer Program membership and a WeatherKit-enabled App ID. If the project later adopts paid provisioning, keep the provider-neutral forecast model, add the required WeatherKit entitlement and Apple Weather attribution, and replace the Open-Meteo service at the provider boundary.

## Desktop acceptance checklist

`./Scripts/verify-widgets.sh` covers stable configuration defaults, city-result encoding and coordinate delivery, the 20-result cap, duplicate-name labels, family-specific layout metrics, expanded large-family selection, all 54 family/view/preset presentation combinations, accessible forecast titles, detail limits and notices, loaded/stale/failure states, exhausted-hour fallback, forecast-city midnight rollover, city-time-zone scheduling, request construction, response decoding, WMO mapping, unit formatting, city errors, cached forecast round trips, the Release extension bundle, and its App Intent metadata.

Those automated contracts are consumed by the SwiftUI view, so configuration and size behavior do not need to be manually repeated before each commit. The remaining checklist is intentionally limited to macOS-owned integration and visual behavior:

- [ ] Add one Weather widget and confirm macOS exposes Search City, Matching City, Forecast View, Temperature Units, and Details Preset editor rows.
- [ ] Type at least two letters in Search City, open Matching City, confirm several state/country-labeled results appear for a common name, choose one, and verify it persists and refreshes the forecast.
- [ ] Add Small, Medium, and Large copies and confirm headers, temperatures, secondary metrics, limit notices, and attribution remain fully visible with comfortable gaps.
- [ ] Compare Medium and Large Week or Hour widgets and confirm Large shows the expanded current-conditions dashboard above its forecast strip.
- [ ] Disconnect networking after one successful load and confirm the extension's sandbox allows the cached forecast to remain visible on the desktop.
- [ ] Verify the Open-Meteo link is visible and opens the provider site.
- [ ] Compare Clear Light, Clear Dark, and Tinted appearances and confirm the content stays readable.
- [ ] Use VoiceOver once to confirm the system traverses each combined forecast label in a sensible order.
