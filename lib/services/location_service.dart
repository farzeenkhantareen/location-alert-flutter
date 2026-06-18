import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final String id;
  final double latitude;
  final double longitude;
  final String name;

  LocationData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
        id: json['id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        name: json['name'] as String,
      );
}

class LocationService {
  static const String _customLocationsKey = 'custom_locations';
  static const String _thresholdKey = 'distance_threshold';

  static final List<LocationData> defaultLocations = [
    LocationData(id: 'default_1', latitude: 33.6844, longitude: 73.0479, name: 'Centaurus Mall'),
    LocationData(id: 'default_2', latitude: 33.7000, longitude: 73.0500, name: 'F-9 Park'),
    LocationData(id: 'default_3', latitude: 33.7100, longitude: 73.0600, name: 'F-10 Markaz'),
  ];

  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Load threshold
  static Future<double> getThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force reload memory cache from disk for multi-isolate sync
    return prefs.getDouble(_thresholdKey) ?? 100.0;
  }

  // Save threshold
  static Future<void> saveThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdKey, threshold);
  }

  // Load all locations (defaults + custom ones)
  static Future<List<LocationData>> getAllLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force reload memory cache from disk for multi-isolate sync
    final customJson = prefs.getStringList(_customLocationsKey) ?? [];
    
    final List<LocationData> customLocations = [];
    for (var str in customJson) {
      try {
        customLocations.add(LocationData.fromJson(jsonDecode(str)));
      } catch (e) {
        print("Error decoding custom location: $e");
      }
    }
    
    return [...defaultLocations, ...customLocations];
  }

  // Add custom location
  static Future<void> addCustomLocation(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getStringList(_customLocationsKey) ?? [];
    
    customJson.add(jsonEncode(location.toJson()));
    await prefs.setStringList(_customLocationsKey, customJson);
  }

  // Remove custom location
  static Future<void> removeCustomLocation(String id) async {
    if (id.startsWith('default_')) return; // Cannot delete default ones
    
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getStringList(_customLocationsKey) ?? [];
    
    final updatedJson = customJson.where((str) {
      try {
        final loc = LocationData.fromJson(jsonDecode(str));
        return loc.id != id;
      } catch (_) {
        return false;
      }
    }).toList();
    
    await prefs.setStringList(_customLocationsKey, updatedJson);
  }
}
