import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class SMSService {
  Future<void> sendSOSMessage({
    required List<String> recipients,
    required String message,
  }) async {
    // 1. Check for SMS Permissions (Android specific)
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }

    // 2. Format recipients for the SMS URI
    final String numbers = recipients.join(',');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: numbers,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    // 3. Fallback: Launch external SMS app
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        // More specific fallback for some Android devices
        final Uri alternateUri = Uri.parse("sms:$numbers?body=${Uri.encodeComponent(message)}");
        if (await canLaunchUrl(alternateUri)) {
          await launchUrl(alternateUri);
        }
      }
    } catch (e) {
      print('Could not launch SMS: $e');
    }
  }

  String generateLocationMessage(String name, double lat, double lng, String address) {
    return "🚨 EMERGENCY SOS 🚨\nI need help! This is $name.\nMy Location: https://www.google.com/maps?q=$lat,$lng\nAddress: $address";
  }
}
