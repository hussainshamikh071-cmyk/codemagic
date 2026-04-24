import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String userId;

  const LiveTrackingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _LiveTrackingScreenState createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final TrackingService _trackingService = TrackingService();
  final MapController _mapController = MapController();
  bool _firstLoad = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Family Live Tracking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _trackingService.getLiveLocationStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _firstLoad) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildNoSessionUI("No active tracking session found.");
          }

          final data = snapshot.data!.data();
          if (data == null) return _buildNoSessionUI("Error parsing tracking data.");

          final bool isActive = data['isActive'] ?? false;
          if (!isActive) {
            return _buildNoSessionUI("User is not currently sharing location.");
          }

          final double lat = data['latitude'] ?? 0.0;
          final double lng = data['longitude'] ?? 0.0;
          final LatLng position = LatLng(lat, lng);
          final Timestamp? timestamp = data['timestamp'] as Timestamp?;
          final String timeString = timestamp != null 
              ? DateFormat('hh:mm:ss a').format(timestamp.toDate()) 
              : "N/A";

          _firstLoad = false;

          // Auto-follow logic
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(position, _mapController.camera.zoom);
          });

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 16.0,
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
                        point: position,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildOverlayUI(isActive, timeString, lat, lng),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoSessionUI(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          const Text("🔴 OFFLINE", style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildOverlayUI(bool isActive, String lastUpdate, double lat, double lng) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('🟢 LIVE', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Text(lastUpdate, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            Row(
              children: [
                const Icon(Icons.my_location, color: Colors.white38, size: 14),
                const SizedBox(width: 8),
                Text(
                  "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}",
                  style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
