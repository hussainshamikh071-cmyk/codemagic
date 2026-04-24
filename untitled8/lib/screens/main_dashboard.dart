import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/navigation_controller.dart';
import '../widgets/bottom_nav_bar.dart';

import 'home_screen.dart';
import 'contacts_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  late final PageController _pageController;

  // ✅ FIX: NO const, NO constructor issues
  final List<Widget> _screens = [
    HomeScreen(),
    ContactsScreen(),
    HistoryScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    final navController =
    Provider.of<NavigationController>(context, listen: false);

    navController.setIndex(index);

    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    final navController =
    Provider.of<NavigationController>(context, listen: false);

    navController.setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Consumer<NavigationController>(
        builder: (context, navController, child) {
          return Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: _screens,
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomBottomNavBar(
                  currentIndex: navController.selectedIndex,
                  onTap: _onItemTapped,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}