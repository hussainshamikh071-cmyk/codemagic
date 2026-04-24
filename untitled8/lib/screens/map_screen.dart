import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/location_service.dart';
import '../services/sos_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final SOSService _sosService = SOSService();

  LatLng _currentPosition = const LatLng(0, 0);
  Position? _rawPosition;
  bool _isLoading = true;
  bool _isSendingSOS = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _rawPosition = position;
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController.move(_currentPosition, 15.0);
      }

      _locationService.locationStream.listen((Position position) {
        if (mounted) {
          setState(() {
            _rawPosition = position;
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          _mapController.move(_currentPosition, _mapController.camera.zoom);
        }
      });
    } catch (e) {
      debugPrint("Location Error: $e");
      _showErrorSnackBar(e.toString());
      setState(() => _isLoading = false);
    }
  }

  // ✅ COMPLETELY FIXED: Get readable address from coordinates
  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Build address parts safely
        List<String> addressParts = [];

        // Safely add each field (handles null, bool, and other types)
        _addSafeAddressPart(addressParts, place.street);
        _addSafeAddressPart(addressParts, place.subLocality);
        _addSafeAddressPart(addressParts, place.locality);
        _addSafeAddressPart(addressParts, place.administrativeArea);
        _addSafeAddressPart(addressParts, place.country);
        _addSafeAddressPart(addressParts, place.name);

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return 'Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  // Helper method to safely add string values
  void _addSafeAddressPart(List<String> list, dynamic value) {
    if (value != null) {
      String strValue = value.toString().trim();
      // Filter out empty strings, "null", and boolean values
      if (strValue.isNotEmpty &&
          strValue != 'null' &&
          strValue != 'false' &&
          strValue != 'true') {
        list.add(strValue);
      }
    }
  }

  Future<void> _handleSOS() async {
    if (_rawPosition == null) {
      _showErrorSnackBar("Waiting for GPS location...");
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('⚠️ Send SOS?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will send your live location to emergency contacts and dial emergency number.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('SEND SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSendingSOS = true);

      try {
        final address = await _getAddressFromCoordinates(
          _rawPosition!.latitude,
          _rawPosition!.longitude,
        );

        final contacts = await SOSService.getContacts();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Sending SOS Alert...',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifying: ${contacts.primary}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        final result = await _sosService.sendSOS(
          latitude: _rawPosition!.latitude,
          longitude: _rawPosition!.longitude,
          address: address,
          contacts: contacts,
        );

        if (mounted) {
          Navigator.pop(context); // Close progress dialog

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'SOS Sent Successfully!',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📱 SMS sent to: ${result.smsSent.join(", ")}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.callStarted
                        ? '📞 Call initiated to primary number'
                        : '⚠️ Could not start call',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Location:',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    address,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: Colors.redAccent)),
                  ),
                )
              ],
            ),
          );
        }
      } catch (e) {
        debugPrint("SOS Error: $e");
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close progress dialog if open
          }
          _showErrorSnackBar("SOS Failed: ${e.toString()}");
        }
      }

      setState(() => _isSendingSOS = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('SOS Live Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.redAccent),
            SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.safety.guardian',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 45,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildMapControls(),
        ],
      ),
      floatingActionButton: _isSendingSOS
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(60),
        ),
        child: const CircularProgressIndicator(color: Colors.redAccent),
      )
          : FloatingActionButton.large(
        onPressed: _handleSOS,
        backgroundColor: Colors.redAccent,
        elevation: 10,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(height: 4),
            Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 20,
      top: 120,
      child: Column(
        children: [
          _buildControlButton(Icons.add, () {
            _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1
            );
          }),
          const SizedBox(height: 10),
          _buildControlButton(Icons.remove, () {
            _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1
            );
          }),
          const SizedBox(height: 10),
          _buildControlButton(Icons.my_location, () {
            _mapController.move(_currentPosition, 15.0);
          }),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }
}