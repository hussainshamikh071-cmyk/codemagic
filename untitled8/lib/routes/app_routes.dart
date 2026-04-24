import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_contacts_screen.dart';
import '../screens/history_screen.dart';
import '../screens/ai_safety_tips.dart';
import '../screens/map_tracker_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/live_tracking_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String contacts = '/contacts';
  static const String history = '/history';
  static const String aiTips = '/ai-tips';
  static const String map = '/map';
  static const String settings = '/settings';
  static const String liveTracking = '/live-tracking';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),

    // ✅ FIXED
    home: (context) => const HomeScreen(),

    profile: (context) => const ProfileScreen(),
    contacts: (context) => const EditContactsScreen(),
    history: (context) => const HistoryScreen(),
    aiTips: (context) => const AISafetyTipsScreen(location: 'Detecting...'),
    map: (context) => const MapTrackerScreen(),
    settings: (context) => const SettingsScreen(),

    liveTracking: (context) {
      final userId = ModalRoute.of(context)!.settings.arguments as String;
      return LiveTrackingScreen(userId: userId);
    },
    '/track': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as String;
      return LiveTrackingScreen(userId: args);
    },
  };
}
