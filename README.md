
# Location Alert Flutter 📍🔔

A Flutter-based smart location monitoring application that sends real-time alerts when users enter configured geographic areas.

The application uses GPS location tracking, geofence-based distance calculation, and local notifications to notify users when they reach saved locations.

Users can create custom locations, configure alert radius, and receive notifications automatically when they enter a defined area.

---

# ✨ Features

## 📍 Smart Location Monitoring

- Real-time GPS location tracking
- Background location monitoring
- Automatic distance calculation between user and saved locations
- Detects when a user enters a configured radius

---

## 🔔 Location-Based Notifications

- Sends local notifications when a location is reached
- Custom location names in notifications
- Prevents repeated notifications while staying inside the same area
- Allows notification triggering again after leaving and re-entering

Example:

```

User enters location radius
↓
Distance calculated
↓
Location matched
↓
Notification sent 🔔

```

---

# 📌 Custom Location Management

Users can create their own monitored locations.

Supported features:

- Add custom latitude
- Add custom longitude
- Add location name
- Configure custom alert radius
- Manage multiple saved locations

Example:

```

Location Name:
Office

Latitude:
33.6844

Longitude:
73.0479

Alert Radius:
500 meters

```

---

# 📏 Adjustable Alert Radius

Users can decide how close they need to be before receiving an alert.

Examples:

```

50 meters
100 meters
500 meters
1 kilometer
Custom radius values

```

The application dynamically calculates the distance between the current device location and saved coordinates.

---

# 📍 Location Accuracy & Fake GPS Handling

## Flutter Version

The Flutter implementation focuses on providing reliable location data.

Features:

✅ Tested with real device GPS coordinates  
✅ Provides original device location coordinates  
✅ Consistent location updates  
✅ Suitable for real-world location monitoring scenarios  

The application does not intentionally modify or replace device coordinates and relies on the actual location provider.

---

## React Native Comparison

The React Native version of this project provides location tracking and geofencing functionality, but it currently does not include fake GPS/mock location detection.

React Native version:

⚠️ Trusts coordinates provided by the device location service  
⚠️ Does not currently filter fake/mock GPS coordinates  
⚠️ Requires additional anti-spoofing logic for high-security applications  

The Flutter version currently provides more reliable coordinate handling for this use case.

---

# 🚀 How It Works

The application stores monitored locations containing:

- Latitude
- Longitude
- Radius
- Location name

The app continuously checks the user's position.

```

Current User Location
|
↓
Get GPS Coordinates
|
↓
Calculate Distance
|
↓
Inside Saved Radius?
|
↓
Send Notification

```

---

# 🛠️ Technologies Used

- Flutter
- Dart
- Geolocator
- Flutter Local Notifications
- Background Location Services
- Permission Handler

---

# 📂 Project Structure

```

lib/

├── main.dart

├── screens/
│   ├── home_screen.dart
│   └── add_location_screen.dart

├── services/
│   ├── location_service.dart
│   ├── notification_service.dart
│   └── background_service.dart

├── models/
│   └── location_model.dart

└── utils/
└── distance_calculator.dart

````

---

# ⚙️ Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/location-alert-flutter.git
````

Navigate to the project:

```bash
cd location-alert-flutter
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

# 🔐 Required Permissions

## Android

The application requires:

* Fine Location Permission
* Background Location Permission
* Notification Permission
* Foreground Service Permission

## iOS

The application requires:

* Location When In Use Permission
* Always Location Permission
* Notification Permission

---

# 📦 Build Android APK

Generate release APK:

```bash
flutter build apk --release
```

APK output:

```
build/app/outputs/flutter-apk/app-release.apk
```

Install the APK on your device and enable:

✅ Location Permission
✅ Background Location Permission
✅ Notification Permission

---

# 🌍 Use Cases

This application can be used for:

* 🚗 Location reminders
* 🏢 Office arrival notifications
* 🏫 Campus alerts
* 📦 Delivery tracking
* 🏠 Smart home triggers
* 🧭 Travel reminders
* 🚘 Vehicle monitoring

---

# 🔮 Future Improvements

* Cloud location synchronization
* User accounts
* Map integration
* Real-time location sharing
* Location history
* Backend validation
* Advanced fake GPS detection
* Multiple device synchronization

---

# 🤝 Contributing

Contributions, issues, and feature requests are welcome.

Feel free to fork this repository and improve the project.

---

# 📄 License

This project is open-source and available under the MIT License.

---

# 👨‍💻 Author

Developed using Flutter ❤️

A smart location alert system built with GPS, geofencing, background tracking, and notifications.
