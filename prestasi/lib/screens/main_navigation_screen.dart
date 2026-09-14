import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_eco_dock.dart';
import 'home_screen.dart';
import 'statistic_screen.dart';
import 'market_screen.dart';
import 'package:prestasi/screens/camera/camera_screen.dart';
import 'package:prestasi/screens/Selko/Screens/profile_screen.dart';
import 'package:prestasi/screens/Selko/Screens/discover_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 5 tab: index 0-4
    // Pasar = index 3, Profil = index 4
    // Jelajah = index 2 (diakses lewat pill)
    final List<Widget> screens = [
      HomeScreen(onNavigateTab: _navigateToTab),   // 0
      const StatisticScreen(),                      // 1
      DiscoverScreen(isDarkMode: _isDarkMode),      // 2
      const MarketScreen(),                         // 3
      ProfileScreen(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        isDarkMode: _isDarkMode,
        onThemeChanged: (bool newTheme) {
          setState(() {
            _isDarkMode = newTheme;
          });
        },
      ),                                            // 4
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomEcoDock(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
        onScanTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        ),
        onDiscoverTap: () => _navigateToTab(2), // pindah tab, bukan push
      ),
    );
  }
}