import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'notification_service.dart';

class MyBackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: NotificationService.channelId,
        initialNotificationTitle: 'Location Alert Service',
        initialNotificationContent: 'Monitoring arrival at specific locations',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    await NotificationService.initialize();

    // Local state variables inside background service isolate
    List<LocationData> locations = [];
    double distanceThreshold = 100.0;

    StreamSubscription<Position>? positionSubscription;

    // 1. REGISTER ALL EVENT LISTENERS FIRST (non-blocking initialization)
    service.on('stopService').listen((event) {
      positionSubscription?.cancel();
      service.stopSelf();
    });

    service.on('updateSettings').listen((event) async {
      try {
        locations = await LocationService.getAllLocations();
        distanceThreshold = await LocationService.getThreshold();
        print("Background service reloaded settings: ${locations.length} locations, threshold: $distanceThreshold meters");
      } catch (e) {
        print("Error reloading settings: $e");
      }
    });

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    // 2. LOAD INITIAL SETTINGS FROM PERSISTENCE
    try {
      locations = await LocationService.getAllLocations();
      distanceThreshold = await LocationService.getThreshold();
    } catch (e) {
      print("Error loading background service settings: $e");
    }

    // 3. START POSITION STREAM (battery optimized)
    Set<String> notifiedLocationIds = {};

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Request updates when moving 5 meters
    );

    positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) async {
      _processPositionUpdate(position, locations, distanceThreshold, notifiedLocationIds, service);
    });

    // 4. FETCH INITIAL POSITION ONCE IMMEDIATELY (non-blocking)
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).then((position) {
      service.invoke('update', {
        "latitude": position.latitude,
        "longitude": position.longitude,
      });
      _processPositionUpdate(position, locations, distanceThreshold, notifiedLocationIds, service);
    }).catchError((e) {
      print("Error getting initial location in background: $e");
    });
  }

  // Helper function to calculate distance and show notifications
  static Future<void> _processPositionUpdate(
    Position position,
    List<LocationData> locations,
    double distanceThreshold,
    Set<String> notifiedLocationIds,
    ServiceInstance service,
  ) async {
    // Send data to UI
    service.invoke('update', {
      "latitude": position.latitude,
      "longitude": position.longitude,
    });

    List<String> nearbyIds = [];
    for (var loc in locations) {
      double distance = LocationService.calculateDistance(
        position.latitude,
        position.longitude,
        loc.latitude,
        loc.longitude,
      );
      if (distance <= distanceThreshold) {
        nearbyIds.add(loc.id);
      }
    }
    
    // Logic: Reset when user leaves radius
    notifiedLocationIds.removeWhere((id) => !nearbyIds.contains(id));

    for (String id in nearbyIds) {
      // Requirement: prevent_duplicate_notifications
      if (!notifiedLocationIds.contains(id)) {
        final loc = locations.firstWhere((l) => l.id == id, orElse: () => LocationData(id: id, latitude: 0, longitude: 0, name: 'Monitored Location'));
        await NotificationService.showNotification(
          id: id.hashCode.abs(), // Ensure positive integer notification ID
          title: 'Location Alert',
          body: 'You have reached ${loc.name}.',
        );
        notifiedLocationIds.add(id);
      }
    }

    // Update foreground notification status (Android only)
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Location Tracking Active",
          content: "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}",
        );
      }
    }
  }
}
