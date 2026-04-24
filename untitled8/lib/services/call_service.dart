import 'package:url_launcher/url_launcher.dart';

class CallService {
  Future<void> makeEmergencyCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      print('Could not launch phone call');
    }
  }
}
