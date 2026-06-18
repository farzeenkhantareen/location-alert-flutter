import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? latitude;
  double? longitude;
  bool isServiceRunning = false;
  bool isTrackingActive = false;
  
  List<LocationData> locations = [];
  double distanceThreshold = 100.0;
  
  StreamSubscription? _serviceSubscription;
  Timer? _statusTimer;

  // Add Custom Location Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadSettings();
    _listenToBackgroundService();
    
    // Check initial service status once on app startup
    FlutterBackgroundService().isRunning().then((running) {
      if (mounted) {
        setState(() {
          isServiceRunning = running;
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final locs = await LocationService.getAllLocations();
    final thres = await LocationService.getThreshold();
    if (mounted) {
      setState(() {
        locations = locs;
        distanceThreshold = thres;
      });
    }
  }

  void _listenToBackgroundService() {
    _serviceSubscription = FlutterBackgroundService().on('update').listen((event) {
      if (mounted) {
        setState(() {
          latitude = event?['latitude'];
          longitude = event?['longitude'];
          isTrackingActive = true;
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            latitude = position.latitude;
            longitude = position.longitude;
          });
        }
      } catch (e) {
        debugPrint("Error getting initial location: $e");
      }
      await Permission.locationAlways.request();
    }
    await Permission.notification.request();
  }

  Future<void> _addNewLocation() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final lat = double.parse(_latController.text.trim());
      final lng = double.parse(_lngController.text.trim());
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';

      final newLoc = LocationData(id: id, latitude: lat, longitude: lng, name: name);
      await LocationService.addCustomLocation(newLoc);
      
      _nameController.clear();
      _latController.clear();
      _lngController.clear();
      
      // Reload UI list
      await _loadSettings();
      
      // Update background service in real-time
      if (isServiceRunning) {
        FlutterBackgroundService().invoke('updateSettings');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added location "$name" successfully!'),
          backgroundColor: Colors.green[800],
        ),
      );
    }
  }

  Future<void> _deleteLocation(String id, String name) async {
    await LocationService.removeCustomLocation(id);
    await _loadSettings();

    // Update background service in real-time
    if (isServiceRunning) {
      FlutterBackgroundService().invoke('updateSettings');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed location "$name"'),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  Future<void> _updateThreshold(double value) async {
    setState(() {
      distanceThreshold = value;
    });
    await LocationService.saveThreshold(value);
    
    // Update background service in real-time
    if (isServiceRunning) {
      FlutterBackgroundService().invoke('updateSettings');
    }
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    _statusTimer?.cancel();
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium dark theme
      appBar: AppBar(
        title: const Text(
          'Location Alert Flutter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLiveDashboard(),
              const SizedBox(height: 20),
              _buildControlPanel(),
              const SizedBox(height: 20),
              _buildThresholdConfigurator(),
              const SizedBox(height: 20),
              _buildAddLocationForm(),
              const SizedBox(height: 24),
              _buildLocationsHeader(),
              const SizedBox(height: 12),
              _buildLocationsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveDashboard() {
    return Card(
      color: const Color(0xFF1E293B).withOpacity(0.8),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE COORDINATES',
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${latitude?.toStringAsFixed(6) ?? 'Waiting...'}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lng: ${longitude?.toStringAsFixed(6) ?? 'Waiting...'}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                RadarAnimation(isActive: isServiceRunning),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem(
                  'Tracking Status',
                  isTrackingActive ? 'ACTIVE' : 'INACTIVE',
                  isTrackingActive ? Colors.greenAccent : Colors.grey,
                ),
                _buildMetricItem(
                  'Service Status',
                  isServiceRunning ? 'RUNNING' : 'STOPPED',
                  isServiceRunning ? Colors.cyanAccent : Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isServiceRunning ? null : () async {
              final service = FlutterBackgroundService();
              final success = await service.startService();
              if (success && mounted) {
                setState(() {
                  isServiceRunning = true;
                });
              }
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text('Start Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // Emerald green
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: !isServiceRunning ? null : () {
              FlutterBackgroundService().invoke('stopService');
              setState(() {
                isServiceRunning = false;
                isTrackingActive = false;
                latitude = null;
                longitude = null;
              });
            },
            icon: const Icon(Icons.stop_rounded, size: 24),
            label: const Text('Stop Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), // Coral red
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFEF4444).withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdConfigurator() {
    return Card(
      color: const Color(0xFF1E293B).withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DISTANCE THRESHOLD',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                ),
                Text(
                  '${distanceThreshold.toInt()} meters',
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.cyanAccent,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.cyanAccent,
                overlayColor: Colors.cyanAccent.withOpacity(0.2),
                valueIndicatorColor: Colors.cyanAccent,
              ),
              child: Slider(
                value: distanceThreshold,
                min: 50.0,
                max: 1000.0,
                divisions: 19,
                label: '${distanceThreshold.toInt()}m',
                onChanged: _updateThreshold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddLocationForm() {
    return Card(
      color: const Color(0xFF1E293B).withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ADD NEW MONITORED LOCATION',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Location Name', Icons.pin_drop),
                validator: (val) => val == null || val.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Latitude', Icons.explore),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal < -90 || numVal > 90) return 'Invalid lat';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Longitude', Icons.explore_outlined),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal < -180 || numVal > 180) return 'Invalid lng';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addNewLocation,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add Monitored Location', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Violet
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 18),
      filled: true,
      fillColor: const Color(0xFF0F172A).withOpacity(0.5),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.cyanAccent, width: 1),
      ),
    );
  }

  Widget _buildLocationsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'MONITORED LOCATIONS (${locations.length})',
          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
        ),
        Text(
          'Radius: ${distanceThreshold.toInt()}m',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildLocationsList() {
    if (locations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No locations configured.',
            style: TextStyle(color: Colors.white30),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final loc = locations[index];
        double? distance;
        bool isInside = false;

        if (latitude != null && longitude != null) {
          distance = LocationService.calculateDistance(
            latitude!,
            longitude!,
            loc.latitude,
            loc.longitude,
          );
          isInside = distance <= distanceThreshold;
        }

        final isCustom = !loc.id.startsWith('default_');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isInside 
                ? const Color(0xFF064E3B).withOpacity(0.8) // Dark green alert color
                : const Color(0xFF1E293B).withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isInside 
                  ? Colors.greenAccent.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: [
              if (isInside)
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    loc.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (isInside)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent, width: 1),
                    ),
                    child: const Text(
                      'INSIDE RADIUS',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Coord: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 4),
                if (distance != null)
                  Text(
                    'Distance: ${distance < 1000 ? "${distance.toStringAsFixed(0)} m" : "${(distance / 1000).toStringAsFixed(2)} km"}',
                    style: TextStyle(
                      color: isInside ? Colors.greenAccent : Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  const Text(
                    'Distance: Waiting for active GPS...',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
              ],
            ),
            trailing: isCustom
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteLocation(loc.id, loc.name),
                  )
                : null,
          ),
        );
      },
    );
  }
}

// Radar Pulse Custom Animation Widget
class RadarAnimation extends StatefulWidget {
  final bool isActive;
  const RadarAnimation({super.key, required this.isActive});

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isActive)
                ...List.generate(2, (index) {
                  final progress = (_controller.value + index / 2) % 1.0;
                  return Container(
                    width: 70 * progress,
                    height: 70 * progress,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity((1 - progress) * 0.6),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: widget.isActive ? Colors.cyanAccent : Colors.white24,
                    width: 2,
                  ),
                  boxShadow: [
                    if (widget.isActive)
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                  ],
                ),
                child: Icon(
                  widget.isActive ? Icons.radar_rounded : Icons.gps_off_rounded,
                  color: widget.isActive ? Colors.cyanAccent : Colors.white30,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
