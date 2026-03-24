# Tripoli Explorer+ - Flutter Application

This is the Flutter version of the Tripoli Explorer+ tourism portal application.

## Quick run (web)

```bash
flutter pub get
flutter run -d chrome
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- iOS Simulator / Android Emulator or physical device

### Installation Steps

1. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the Application**
   - **Web (recommended, no Android JDK needed):**
     ```bash
     flutter run -d chrome
     ```
   - Or run and choose a device when prompted:
     ```bash
     flutter run
     ```
   - **Android:** Requires JDK 17 or 21 (see Troubleshooting if you have JDK 25).

### Sign in with Apple (required setup)

Apple Sign-In needs a [paid Apple Developer Program](https://developer.apple.com/programs/) account.

**Backend (Render / `.env`)**

- Set `APPLE_CLIENT_IDS` to a **comma-separated** list of JWT audiences:
  - **iOS:** your App ID / bundle identifier (e.g. `com.yourcompany.tripoli_explorer`).
  - **Android:** your **Services ID** (e.g. `com.yourcompany.tripoli_explorer.signin`) — create under Identifiers → Services IDs, enable Sign in with Apple, and add **Return URLs**:
    - `https://<your-api-host>/api/auth/apple/android-return`  
    (must match exactly; use HTTPS, not a LAN IP).
- Set `ANDROID_PACKAGE_NAME` to the same value as `applicationId` in `android/app/build.gradle.kts` (default `com.example.tripoli_explorer`).
- `APPLE_CLIENT_ID` or `APPLE_SERVICE_ID` alone still works for a **single** audience, but two values need `APPLE_CLIENT_IDS`.

**Flutter Android build**

Pass your Services ID (and optional redirect override):

```bash
flutter run --dart-define=APPLE_SERVICE_ID=com.yourcompany.tripoli_explorer.signin
# optional if the default API URL is wrong for the registered Return URL:
flutter run --dart-define=APPLE_REDIRECT_URI=https://your-api.onrender.com/api/auth/apple/android-return
```

If `APPLE_REDIRECT_URI` is omitted, the app uses `{API_BASE_URL or override}/api/auth/apple/android-return` — it must be **HTTPS** and registered in Apple’s Return URLs.

**Flutter iOS (Xcode)**

- Add the **Sign in with Apple** capability to the Runner target.
- Bundle ID must be one of the values in `APPLE_CLIENT_IDS` on the server.

**Web**

- Add Apple’s JS to `web/index.html` as described in the [`sign_in_with_apple`](https://pub.dev/packages/sign_in_with_apple) package; register your web domain and return URLs in the Services ID.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── place.dart
│   └── trip.dart
├── providers/               # State management (Provider)
│   ├── app_state.dart
│   ├── auth_provider.dart
│   ├── places_provider.dart
│   ├── trips_provider.dart
│   └── map_provider.dart
├── screens/                  # App screens
│   ├── login_screen.dart
│   ├── explore_screen.dart
│   ├── place_details_screen.dart
│   ├── trips_screen.dart
│   ├── map_screen.dart
│   ├── profile_screen.dart
│   ├── ai_planner_screen.dart
│   ├── interests_screen.dart
│   ├── admin_dashboard_screen.dart
│   ├── business_dashboard_screen.dart
│   ├── tour_detail_screen.dart
│   └── event_detail_screen.dart
├── widgets/                  # Reusable widgets
│   ├── place_card.dart
│   └── category_card.dart
├── routes/                   # Navigation routing
│   └── app_router.dart
└── theme/                    # App theming
    └── app_theme.dart
```

## Features Implemented

✅ **Authentication**
- Login with email/password
- Social login (Google, Apple)
- Guest mode
- User session management

✅ **Explore Screen**
- Place listings with categories
- Search functionality
- Place cards with images
- Category filtering
- Save/unsave places

✅ **Place Details**
- Full place information
- Image gallery
- Add to trip functionality
- Directions and map integration

✅ **Trips Management**
- Create new trips
- View all trips
- Date selection
- Trip planning

✅ **Map Integration**
- Interactive map with markers
- Current location
- Place markers
- Route planning (basic)

✅ **Profile**
- User information
- Saved places count
- Settings and preferences

✅ **State Management**
- Provider pattern for state management
- Persistent storage with SharedPreferences
- Data loading from JSON files

## Data Files

The app loads data from JSON files in the `data/` directory:
- `locations.json` - Places data
- `tours.json` - Tour information
- `events.json` - Event listings
- `interests.json` - Interest categories
- `users.json` - User data

Make sure these files are in the `data/` folder and properly formatted.

## Dependencies

Key packages used:
- `provider` - State management
- `go_router` - Navigation
- `shared_preferences` - Local storage
- `flutter_map` - Map functionality
- `geolocator` - Location services
- `cached_network_image` - Image caching
- `font_awesome_flutter` - Icons

## Next Steps

To complete the full conversion:

1. **Install dependencies**: Run `flutter pub get`
2. **Add data files**: Ensure all JSON files are in `data/` folder
3. **Test on device**: Run `flutter run`
4. **Implement remaining features**:
   - Complete AI Planner functionality
   - Complete Admin Dashboard
   - Complete Business Dashboard
   - Add tour and event detail screens
   - Implement interests selection
   - Add more map features (routing, etc.)

## Notes

- The app uses Material Design 3
- All screens are responsive
- State is managed using Provider pattern
- Data persistence uses SharedPreferences
- Map functionality uses flutter_map with OpenStreetMap tiles

## Troubleshooting

If you encounter errors:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter pub upgrade`
4. Check that all data files exist in `data/` folder
5. Ensure Flutter SDK is up to date

### Android build fails with "25.0.1" or "Unresolved reference: pluginManagement"

The Android build uses Gradle’s Kotlin DSL, which does **not** support JDK 25. Use **JDK 17 or 21** for building.

**Option 1 – Set JAVA_HOME (recommended)**  
Point `JAVA_HOME` to a JDK 17 or 21 installation before building:

- **Windows (PowerShell):**
  ```powershell
  $env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
  flutter build apk --debug
  ```
- **Windows (Command Prompt):**
  ```cmd
  set JAVA_HOME=C:\Program Files\Java\jdk-17
  flutter build apk --debug
  ```
- **macOS/Linux:**  
  `export JAVA_HOME=/path/to/jdk-17` then run `flutter build apk --debug`.

Install JDK 17 from [Adoptium](https://adoptium.net/) or [Oracle](https://www.oracle.com/java/technologies/downloads/#java17) if needed.

**Option 2 – Force Gradle to use a specific JDK**  
In `android/gradle.properties`, set (and adjust the path for your machine):

```properties
org.gradle.java.home=C\:\\Program Files\\Java\\jdk-17
```

Then run `flutter build apk --debug` again.


