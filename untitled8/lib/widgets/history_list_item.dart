import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryListItem extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;

  const HistoryListItem({
    Key? key,
    required this.alert,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = (alert['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('MMM dd, hh:mm a').format(timestamp)
        : 'Unknown Time';
    
    final bool isActive = alert['status'] == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isActive ? Colors.redAccent : Colors.greenAccent).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: isActive ? Colors.redAccent : Colors.greenAccent,
          ),
        ),
        title: Text(
          'Trigger: ${alert['triggered_by'] ?? 'Manual'}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          formattedDate,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isActive ? 'ACTIVE' : 'RESOLVED',
              style: TextStyle(
                color: isActive ? Colors.redAccent : Colors.greenAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
