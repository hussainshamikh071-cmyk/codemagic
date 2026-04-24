import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../repositories/alert_repository.dart';
import '../services/auth_service.dart';
import 'emergency_history_detail.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late AlertRepository _alertRepository;

  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();

    // ✅ SAFE initialization using Future.microtask
    Future.microtask(() {
      final authService =
      Provider.of<AuthService>(context, listen: false);

      final uid = authService.currentUser?.uid;

      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      _alertRepository = AlertRepository(userId: uid);
      _fetchAlerts();
    });
  }

  Future<void> _fetchAlerts() async {
    if (!_hasMore) return;

    setState(() {
      if (_alerts.isEmpty) {
        _isLoading = true;
      } else {
        _isFetchingMore = true;
      }
    });

    try {
      final newAlerts = await _alertRepository.getAlerts(
        limit: 10,
        startAfter: _lastDocument,
      );

      if (!mounted) return;

      setState(() {
        if (newAlerts.length < 10) {
          _hasMore = false;
        }

        if (newAlerts.isNotEmpty) {
          _lastDocument = newAlerts.last['docSnapshot'] as DocumentSnapshot?;
        }

        _alerts.addAll(newAlerts);
        _isLoading = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Emergency History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      )
          : _alerts.isEmpty
          ? const Center(
        child: Text(
          'No alerts found',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _alerts.length) {
            _fetchAlerts();
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.redAccent),
              ),
            );
          }

          final alert = _alerts[index];

          final timestamp =
          (alert['timestamp'] as Timestamp?)?.toDate();

          final formattedDate = timestamp != null
              ? DateFormat('MMM dd, yyyy - hh:mm a')
              .format(timestamp)
              : 'Unknown Date';

          return Card(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                alert['status'] == 'active'
                    ? Colors.red
                    : Colors.green,
                child: Icon(
                  alert['status'] == 'active'
                      ? Icons.warning
                      : Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                'Triggered by: ${alert['triggered_by'] ?? 'Manual'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.white38,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmergencyHistoryDetail(alert: alert),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}