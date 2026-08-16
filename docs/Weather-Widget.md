# Weather Widget

The Weather widget recreates the supplied reference's quiet visual rhythm: a monospaced city label, evenly spaced forecast columns, simple condition symbols, rounded white type, and no app-drawn card behind the content. The wallpaper remains outside the widget; macOS may still place its own Liquid Glass surface over a clear widget.

## Add and customize it

1. Open `DesktopWidgets.xcodeproj`, select **My Mac**, and run the `DesktopWidgets` scheme once.
2. Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and add **Weather**.
3. Control-click the placed widget and choose **Edit Weather**.
4. Configure these settings for that widget instance:

| Setting | Behavior |
| --- | --- |
| City | Enter a city name. Include a state, province, or country when names are ambiguous, such as `Portland, Oregon`. Blank input uses the documented Portland default. An unmatched city shows an error instead of silently displaying another city. |
| Forecast View | **Week** shows seven days on medium and large widgets; a small widget focuses on today. **Day** shows current conditions and today's high/low. **Hour** shows the next six hours, or three on a small widget. |
| Temperature Units | **Automatic** follows the Mac's regional temperature and wind conventions. Explicit Fahrenheit uses mph; explicit Celsius uses km/h. |
| Show Temperature | Shows the current or forecast temperature. |
| Show Condition | Adds a written description to the condition symbol. |
| Show Humidity | Adds relative humidity. |
| Show Chance of Rain | Adds precipitation probability. |
| Show Wind | Adds wind speed. |

If every detail switch is off, the condition remains visible so the widget never becomes an empty city label. All selected details are rendered; selecting many details in a medium seven-column forecast intentionally uses compact labels.

Each placed widget owns its configuration. One instance can show Portland's week in Fahrenheit while another shows Tokyo's next six hours in Celsius.

## Data source and refresh behavior

This personal, subscription-free build uses [Open-Meteo's Forecast API](https://open-meteo.com/en/docs) and [Geocoding API](https://open-meteo.com/en/docs/geocoding-api). It requests current conditions, seven daily forecasts, and hourly forecasts in one refresh. The normalized model includes temperature, relative humidity, precipitation probability, wind speed, and WMO weather condition codes.

The free endpoint is keyless and limited to noncommercial use under [Open-Meteo's current terms](https://open-meteo.com/en/terms). Forecast data is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), so the widget displays a linked **Open-Meteo** credit next to the city. Values are normalized into the app's provider-neutral model and rounded for display. City lookup is based on [GeoNames](https://www.geonames.org/) data. A commercial release must use an appropriately licensed provider or a paid Open-Meteo endpoint and must not embed an API key directly in a public client.

WidgetKit receives several future hourly entries from one forecast response and asks for fresh data approximately hourly. Forecast times use Unix timestamps so repeated local hours around daylight-saving transitions remain unambiguous. The system owns the actual schedule and may delay or coalesce refreshes. If a refresh fails, the widget shows the last successful forecast with a visible last-updated label and retries later. If the city has never loaded, it shows a focused error with editing guidance.

## Privacy

- The widget sends the entered city to Open-Meteo's geocoding endpoint, then sends the matched coordinate to its forecast endpoint.
- Open-Meteo states that service logs can contain IP addresses, request URLs, and coordinates for troubleshooting and may retain them for up to 90 days; see its [Terms & Privacy](https://open-meteo.com/en/terms).
- To reduce requests, the extension stores one recent normalized forecast per city/unit for up to 24 hours and one resolved city coordinate for up to 30 days. Cache filenames use hashes and each cache is capped at 12 entries. These are user-entered city matches, not device-location or movement data. The widget does not request precise device location, use analytics, or commit cities to source control.
- No WeatherKit entitlement, Apple Developer Program membership, API key, account, or Location Services permission is required for this implementation.

## Appearance and accessibility

- The widget declares a clear, removable WidgetKit container exactly like Time & Date. With macOS's Clear icon and widget style, the system may replace that background with Liquid Glass, tint, or blur; WidgetKit does not provide an API to remove the system-owned surface.
- White text and multicolor SF Symbols follow the reference. Every forecast column combines its day or hour, condition, and selected values into one VoiceOver label so color and symbols are not the only source of meaning.
- The small Week layout deliberately becomes a readable Today layout instead of compressing seven columns beyond legibility.
- Bright wallpapers can reduce white-text contrast. Clear Light generally provides the softest glass appearance, while a darker wallpaper region improves readability.

## Signing and networking

The widget extension enables the macOS App Sandbox **Outgoing Connections (Client)** entitlement because it contacts Open-Meteo over HTTPS. This entitlement works with the existing teamless **Sign to Run Locally** setup.

Apple WeatherKit was not selected because Apple's [WeatherKit account setup](https://developer.apple.com/help/account/services/weatherkit/) requires Apple Developer Program membership and a WeatherKit-enabled App ID. If the project later adopts paid provisioning, keep the provider-neutral forecast model, add the required WeatherKit entitlement and Apple Weather attribution, and replace the Open-Meteo service at the provider boundary.

## Desktop acceptance checklist

Automated tests cover stable configuration defaults, every editor choice, request construction, response decoding, WMO mapping, unit formatting, city errors, and cached forecast round trips. WidgetKit's editor, network sandbox, and final layout still need a short desktop check:

- [ ] Run the app once, add Weather in small, medium, and large sizes, and confirm Portland data loads.
- [ ] Edit one instance to a distinct city and confirm the resolved city appears instead of Portland.
- [ ] Switch among Week, Day, and Hour and confirm each presentation changes immediately.
- [ ] Turn each detail on and off, reopen the editor, and confirm the choices persist independently per widget.
- [ ] Disconnect networking after one successful load and confirm the saved forecast plus last-updated label appears.
- [ ] Enter a clearly invalid city and confirm the widget shows the city error without substituting another location.
- [ ] Verify the Open-Meteo link is visible and opens the provider site.
- [ ] Compare Clear Light, Clear Dark, and Tinted appearances and confirm the content stays readable.
