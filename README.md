# Zmanim+

A modern iOS-native zmanim (Jewish prayer times) app. SwiftUI, iOS 17+, Mac Catalyst, SwiftData + CloudKit, WidgetKit.

Inspired by *Ultimate Zmanim*, rebuilt to feel like a first-party Apple app with:

- **Multiple halachic opinions per zman** (Vilna Gaon, Mogen Avraham, degree/minute variants) — user picks what to show.
- **Multi-location + Travel Mode** — saved cities, GPS auto-switch, switch banner when you move.
- **Smart notifications** — per-zman alerts with custom offsets (e.g. Shkia − 15 min, Sefira before Tzeit).
- **Widgets** — Home, Lock Screen, StandBy; Next-Zman with live countdown.
- **iCloud sync** — zero-account; saved locations, preferences, notification rules sync across your devices.

## Repository layout

```
Zmanim/                      iOS / Mac Catalyst app target
  App/                       @main entry + RootView
  Features/                  One folder per feature
    Today/                   Today's zmanim + Next-Zman hero + calendar section
    Locations/               Saved locations, search, travel mode
    Settings/                Opinions editor, preferences, notification rules
    Detail/                  Zman detail sheet
  Resources/                 Assets.xcassets, Localizable.xcstrings

ZmanimKit/                   Local SwiftPM package (shared app + widget)
  Sources/ZmanimKit/
    Models/                  SwiftData models + value types
    Zmanim/                  ZmanimEngine wrapping KosherCocoa
    Calendar/                Hebrew date, Parsha, Daf Yomi, Sefirat Ha'Omer
    Location/                LocationManager, LocationSearch (MKLocalSearch)
    Notifications/           NotificationScheduler
    Persistence/             Shared ModelContainer (App Group + CloudKit)
  Tests/ZmanimKitTests/      Reference-time regression tests

ZmanimWidget/                WidgetKit extension target
  Intents/                   App Intents (refresh, open-in-app)

Config/                      Info.plist fragments, entitlements
```

## Setting up the Xcode project

This repo ships as **source only** — you'll create the `.xcodeproj` in Xcode on your Mac. Takes ~5 minutes.

1. **Create project**  
   `File → New → Project → iOS → App`  
   - Product name: `Zmanim`  
   - Interface: SwiftUI  
   - Language: Swift  
   - Storage: SwiftData  
   - Include Tests: yes  
   Save it **inside this repo's root**, replacing the stub `Zmanim/` folder (keep the source files — just let Xcode manage the `.xcodeproj`).

2. **Add ZmanimKit as a local package**  
   `File → Add Package Dependencies… → Add Local…` → select the `ZmanimKit/` folder. Add it to the app target.

3. **Add KosherCocoa**  
   `ZmanimKit/Package.swift` already declares the dependency on `https://github.com/MosheBerman/KosherCocoa`. Xcode will resolve it automatically.

4. **Enable Mac Catalyst**  
   Target → General → Supported Destinations → add *Mac (Designed for iPad)* and then *Mac Catalyst*. Minimum iOS 17.

5. **Add the Widget target**  
   `File → New → Target → Widget Extension` named `ZmanimWidget`. Replace the generated files with the ones in `ZmanimWidget/`. Add ZmanimKit to the widget target as well.

6. **Capabilities** (app + widget targets)
   - App Groups → `group.com.yourbundle.zmanim` (update constant in `ModelContainer+Shared.swift`).
   - iCloud → CloudKit → container `iCloud.com.yourbundle.zmanim`.
   - Background Modes → *Background fetch* and *Location updates*.
   - Push Notifications is **not** required (we use local notifications only).

7. **Info.plist keys** (app target) — see `Config/Info-additions.plist`:
   - `NSLocationWhenInUseUsageDescription`
   - `NSLocationAlwaysAndWhenInUseUsageDescription` (for Travel Mode)
   - `BGTaskSchedulerPermittedIdentifiers` → `["com.yourbundle.zmanim.refresh"]`

8. **Run**  
   `⌘R` on an iOS 17 simulator. First launch asks for location permission; grant it and you should see today's zmanim for your current city.

## Architecture notes

- **Zmanim are never persisted.** They're a pure function of (date, lat, lon, elevation, opinion). `ZmanimEngine.zmanim(for:at:opinions:)` is the single entry point.
- **SwiftData + CloudKit** for `SavedLocation`, `UserPreferences`, `NotificationRule`. The container lives in the App Group so the widget reads the same store.
- **Notifications** are local `UNNotificationRequest`s, scheduled 14 days out. `BGAppRefreshTask` re-schedules daily; `NotificationScheduler` also re-schedules on location or settings change.
- **Travel Mode** uses `CLLocationManager.startMonitoringSignificantLocationChanges` (low battery cost). On change we surface a banner; user taps to switch.

## Testing

```
swift test --package-path ZmanimKit
```

Reference times for a few known dates/locations live in `ZmanimKitTests/ReferenceZmanimTests.swift`. Sourced from KosherJava's reference output.

## License

TBD
