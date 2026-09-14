import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Global Widgets
import '../widgets/bento_header_card.dart';

// Home-Specific Component Widgets
import '../widgets/home/home_top_app_bar.dart';
import '../widgets/home/home_greeting.dart';
import '../widgets/home/home_quick_actions.dart';
import '../widgets/home/home_mini_stats.dart';
import '../widgets/home/home_leaderboard_section.dart';

// Screen Navigations
import 'package:prestasi/screens/camera/camera_screen.dart';
import 'package:prestasi/screens/Selko/Screens/profile_screen.dart';
import 'package:prestasi/screens/modul/ModuleListScreen.dart';
import 'package:prestasi/screens/statistic_screen.dart';
import 'package:prestasi/screens/market_screen.dart';


class HomeScreen extends StatefulWidget {
  // 1. Variabel untuk menerima fungsi pindah tab dari MainScreen
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final Color primaryColor = const Color(0xFF1E7D4E);
  final Color backgroundColor = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    // PERBAIKAN: Menunggu frame selesai sebelum menjalankan pengecekan Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndResetDailyPoints();
    });
  }

  // LOGIKA RESET HARIAN
  void _checkAndResetDailyPoints() async {
    final uid = currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final doc = await userDocRef.get();
      
      // PERBAIKAN: Cek apakah widget masih ada (mounted) sebelum memproses
      if (!mounted || !doc.exists) return;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final now = DateTime.now();
      String todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      String lastResetDate = data['lastResetDate'] ?? '';

      if (lastResetDate != todayDateStr) {
        await userDocRef.update({
          'todayPoints': 0,
          'today_points': 0, 
          'lastResetDate': todayDateStr,
        });
      }
    } catch (e) {
      debugPrint("Gagal memeriksa reset harian: $e");
    }
  }

  void _goToProfile() {
  widget.onNavigateTab(4);
}

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid ?? '').snapshots(),
      builder: (context, userSnapshot) {
        Map<String, dynamic> userData = {};
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          userData = userSnapshot.data!.data() as Map<String, dynamic>;
        }

        int points = userData['points'] ?? 0;
        String name = userData['displayName'] ?? "User";
        String photo = userData['photoUrl'] ?? "";
        String domain = userData['campusDomain'] ?? "ustb.ac.id";

        int totalPhotos = userData['totalPhotos'] ?? userData['total_photos'] ?? 0;
        int todayPoints = userData['todayPoints'] ?? userData['today_points'] ?? 0;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // 1. TOP APP BAR
                  HomeTopAppBar(photo: photo, onProfileTap: _goToProfile),
                  const SizedBox(height: 30),

                  // 2. GREETINGS
                  HomeGreeting(name: name, onProfileTap: _goToProfile),
                  const SizedBox(height: 25),

                  // 3. MODULAR BENTO HEADER
                  BentoHeaderCard(points: points, primaryColor: primaryColor),
                  const SizedBox(height: 24),

                  // 4. QUICK ACTIONS
                  HomeQuickActions(
                    onScanTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CameraScreen()),
                    ),
                    onTukarPoinTap: () => widget.onNavigateTab(2),
                    onModuleTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModuleListScreen(
                          isLecturer: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF1E7D4E),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Lanjutkan Belajar",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userData['lastCourse'] ?? "Perancangan Web",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (userData['courseProgress'] ?? 0) / 100,
                                color: primaryColor,
                                backgroundColor: Colors.grey.shade300,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ModuleListScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Lanjut",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. MINI STATUS CARDS
                  HomeMiniStats(totalPhotos: totalPhotos, todayPoints: todayPoints),
                  const SizedBox(height: 30),

                  // 6. LEADERBOARD STREAM SECTION
                  HomeLeaderboardSection(
                    domain: domain,
                    primaryColor: primaryColor,
                    onSeeAllTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticScreen())),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}