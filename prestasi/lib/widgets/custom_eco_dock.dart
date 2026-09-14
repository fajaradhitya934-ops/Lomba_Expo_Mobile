import 'package:flutter/material.dart';

class CustomEcoDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onScanTap;
  final VoidCallback onDiscoverTap;

  const CustomEcoDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
    required this.onDiscoverTap,
  });

  static const Color _green = Color(0xFF1E7D4E);
  static const Color _inactive = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Navbar background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  _buildNavItem(Icons.home_rounded, 'Beranda', 0),
                  _buildNavItem(Icons.bar_chart_rounded, 'Statistik', 1),
                  const Spacer(flex: 2),
                  _buildNavItem(Icons.shopping_bag_rounded, 'Penukaran', 3),
                  _buildNavItem(Icons.person_rounded, 'Profil', 4),
                ],
              ),
            ),
          ),

          // Floating pill
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPillItem(Icons.center_focus_strong, 'Scan', onScanTap),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    _buildPillItem(Icons.explore_rounded, 'Jelajah', onDiscoverTap),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
     final bool isActive = currentIndex >= 0 && currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        splashColor: _green.withOpacity(0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? _green.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 22,
                  color: isActive ? _green : _inactive),
            ),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? _green : _inactive,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: const BoxDecoration(
                  color: _green, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 3),
          Text(label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}