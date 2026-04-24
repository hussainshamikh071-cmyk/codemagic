import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmergencyHistoryDetail extends StatelessWidget {
  final Map<String, dynamic> alert;

  const EmergencyHistoryDetail({Key? key, required this.alert}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = (alert['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('EEEE, MMM dd, yyyy - hh:mm a').format(timestamp)
        : 'Unknown Date';
    
    final lat = alert['location']?['lat'] as double?;
    final lng = alert['location']?['lng'] as double?;
    final position = (lat != null && lng != null) ? LatLng(lat, lng) : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Alert Details'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 25),
            _buildInfoSection('Time & Date', formattedDate, Icons.calendar_today),
            _buildInfoSection('Trigger Method', alert['triggeredBy'] ?? 'Manual', Icons.touch_app),
            _buildInfoSection('Address', alert['address'] ?? 'Location recorded', Icons.location_on),
            const SizedBox(height: 25),
            const Text(
              'Location at time of alert',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (position != null)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FlutterMap(
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
                              color: Colors.redAccent,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
            if (alert['status'] == 'active')
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('alerts')
                        .doc(alert['id'])
                        .update({'status': 'resolved'});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Mark as Resolved'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    bool isActive = alert['status'] == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: isActive ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isActive ? Colors.red : Colors.green),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.warning : Icons.check_circle, 
               color: isActive ? Colors.red : Colors.green),
          const SizedBox(width: 15),
          Text(
            isActive ? 'ACTIVE EMERGENCY' : 'RESOLVED INCIDENT',
            style: TextStyle(
              color: isActive ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
