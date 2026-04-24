import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/sos_emergency_service.dart';
import 'services/gemini_ai_service.dart';
import 'services/settings_service.dart';
import 'controllers/navigation_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_dashboard.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_contacts_screen.dart';
import 'screens/history_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<GeminiAIService>(create: (_) => GeminiAIService()),
        ChangeNotifierProvider<SettingsService>(create: (_) => SettingsService()),
        ChangeNotifierProvider<NavigationController>(create: (_) => NavigationController()),
        ProxyProvider<AuthService, SOSEmergencyService>(
          update: (_, auth, __) => SOSEmergencyService(),
        ),
      ],
      child: MaterialApp(
        title: 'Safety Guardian',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/home': (context) => const MainDashboard(),
          '/profile': (context) => ProfileScreen(),
          '/contacts': (context) => EditContactsScreen(),
          '/history': (context) => HistoryScreen(),
        },
      ),
    );
  }
}
