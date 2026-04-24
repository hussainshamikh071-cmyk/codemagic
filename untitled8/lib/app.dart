import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

class SOSGuardianApp extends StatelessWidget {
  const SOSGuardianApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      // Error Boundary: Handle routing errors
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
