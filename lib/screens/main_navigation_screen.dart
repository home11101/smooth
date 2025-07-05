import '../utils/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/smooth_modal_menu.dart';
import 'main_screen_1.dart';
import 'main_screen_2.dart';
import 'premium_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MainScreen1(),
    const MainScreen2(),
  ];

  void _openMenu() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (modalContext) => SmoothModalMenu(
        onUpgrade: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PremiumScreen(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.mainBackgroundGradient,
        ),
        child: Column(
          children: [
            // Header personnalisé avec icône menu et logo
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black, size: 24),
                      onPressed: _openMenu,
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Espace pour équilibrer le layout
                  ],
                ),
              ),
            ),
            Expanded(
              child: _screens[_currentIndex],
            ),
            CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
} 