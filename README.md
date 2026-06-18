# Location Alert Flutter

A production-ready Flutter application that monitors device location in the background and notifies the user when they enter specific predefined areas (within 100 meters).

## Features
- **Background Tracking**: Continuously monitors location even when the app is minimized or the screen is locked.
- **Location Alerts**: Local notifications triggered when entering a 100m radius of monitored coordinates.
- **State Management**: Real-time UI updates for current latitude, longitude, and tracking status.
- **Battery Optimized**: Uses `geolocator` with efficient distance filtering.
- **Cross-Platform**: Configured for both Android and iOS.

## Prerequisites
- Flutter SDK (version 3.9.2 or higher as per project config)
- Physical device (Location services and background modes are best tested on real hardware)

## Setup Instructions

### Android Configuration
The `AndroidManifest.xml` is already configured with:
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_LOCATION`
- `POST_NOTIFICATIONS`

### iOS Configuration
The `Info.plist` is already configured with:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `UIBackgroundModes`: `location` and `fetch`

## Run Instructions

1. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

3. **In-App Steps**:
   - Grant all requested permissions (Location -> 'Allow all the time', Notifications -> 'Allow').
   - Tap **Start Tracking** to begin the background service.
   - You will see a persistent notification indicating the service is active.
   - When you move within 100m of the hardcoded coordinates in `location_service.dart`, a high-priority alert will trigger.

## Monitored Locations (Hardcoded)
- **ID 1**: 33.6844, 73.0479
- **ID 2**: 33.7000, 73.0500
- **ID 3**: 33.7100, 73.0600

## Architecture
- `lib/services/location_service.dart`: Logic for distance calculation and coordinate checks.
- `lib/services/notification_service.dart`: Wrapper for `flutter_local_notifications`.
- `lib/services/background_service.dart`: Background execution logic using `flutter_background_service`.
- `lib/screens/home_screen.dart`: Main UI for status monitoring and control.
