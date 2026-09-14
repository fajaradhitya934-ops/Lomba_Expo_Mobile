import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prestasi/screens/kuis/quiz_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prestasi/screens/modul/PdfViewerScreen.dart';

class CourseMapScreen extends StatelessWidget {
  final String courseId;
  final String courseName;

  const CourseMapScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  Map<String, dynamic> _getBiomeTheme() {
    switch (courseId.toLowerCase()) {
      case 'basis_data':
        return {
          'bg': const Color(0xFFF1F5F9),
          'primary': const Color(0xFF64748B),
          'accent': const Color(0xFF38BDF8),
          'subtitle': "Dungeon Penyimpanan & Relasi Data",
        };
      case 'perancangan_web':
        return {
          'bg': const Color(0xFFFAFAFA),
          'primary': const Color(0xFF0EA5E9),
          'accent': const Color(0xFF22C55E),
          'subtitle': "Cyber City Pemrograman Web",
        };
      case 'keamanan_sistem':
        return {
          'bg': const Color(0xFFFEF2F2),
          'primary': const Color(0xFFEF4444),
          'accent': const Color(0xFF7C3AED),
          'subtitle': "Fortress Pertahanan Jaringan",
        };
      case 'pemrograman_mobile':
        return {
          'bg': const Color(0xFFF0FDF4),
          'primary': const Color(0xFF3B82F6),
          'accent': const Color(0xFFFBBF24),
          'subtitle': "Floating Island Aplikasi Mobile",
        };
      default:
        return {
          'bg': const Color(0xFFFFFDF6),
          'primary': const Color(0xFFC084FC),
          'accent': const Color(0xFF4ADE80),
          'subtitle': "Peta Kelas Petualangan",
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getBiomeTheme();

    return Scaffold(
      backgroundColor: theme['bg'],
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: GridBackgroundPainter())),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .collection('modules')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                List<QueryDocumentSnapshot> modules = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  modules = snapshot.data!.docs;
                }

                if (modules.isEmpty) return _buildEmptyState();

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 130, bottom: 60, left: 20, right: 20),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned.fill(child: CustomPaint(painter: CombinedRoutePainter(totalItems: modules.length))),
                          Column(
                            children: List.generate(modules.length, (index) {
                              final module = modules[index];
                              final moduleData = module.data() as Map<String, dynamic>;

                              final String moduleId = module.id;
                              final String moduleName = (moduleData['name'] ?? moduleData['title'] ?? module.id).toString().toUpperCase();
                              final bool isCompleted = moduleData['is_completed'] ?? false;
                              final List<dynamic> summaryPoints = moduleData['summary_points'] ?? [];

                              final String type = (moduleData['type'] ?? '').toString().toLowerCase();
                              final bool isQuiz = type == 'quiz' || type == 'kuis' || moduleId.contains('quiz');

                              bool isLocked = false;
                              if (index > 0) {
                                final prevModuleData = modules[index - 1].data() as Map<String, dynamic>;
                                final dynamic isPrevCompletedRaw = prevModuleData['is_completed'];
                                final bool prevCompleted = (isPrevCompletedRaw is bool) ? isPrevCompletedRaw : false;
                                isLocked = !prevCompleted;
                              }
                              if (index == 0) isLocked = false;

                              double horizontalBias = (index % 4 == 0) ? -0.6 : ((index % 4 == 1 || index % 4 == 3) ? 0.0 : 0.6);

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 24),
                                child: Align(
                                  alignment: Alignment(horizontalBias, 0),
                                  child: _buildIslandNode(
                                    context,
                                    moduleData: moduleData,
                                    theme: theme,
                                    moduleId: moduleId,
                                    name: moduleName,
                                    stageNumber: index + 1,
                                    isCompleted: isCompleted,
                                    isLocked: isLocked,
                                    isQuiz: isQuiz,
                                    summaryPoints: summaryPoints,
                                    fileUrl: moduleData['fileUrl'] ?? '',
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            _buildBrutalAppBar(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildIslandNode(
    BuildContext context, {
    required Map<String, dynamic> theme,
    required Map<String, dynamic> moduleData,
    required String moduleId,
    required String name,
    required int stageNumber,
    required bool isCompleted,
    required bool isLocked,
    required bool isQuiz,
    required List<dynamic> summaryPoints,
    required String? fileUrl,
  }) {
    Color islandColor;
    IconData islandIcon;
    String badgeText = "STEP 0$stageNumber";

    if (isLocked) {
      islandColor = const Color(0xFFCBD5E1);
      islandIcon = Icons.lock_rounded;
      badgeText = "LOCKED";
    } else {
      if (isQuiz) {
        islandColor = const Color(0xFFFF4A4A);
        islandIcon = Icons.emoji_events_rounded;
        badgeText = "BOSS";
      } else {
        islandColor = theme['accent'];
        islandIcon = isCompleted ? Icons.check_circle_rounded : Icons.menu_book_rounded;
      }
    }

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Akses Terkunci! Selesaikan tantangan sebelumnya."), backgroundColor: Color(0xFFFF4A4A)));
          return;
        }

        if (isQuiz) {
          final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                courseId: courseId,
                moduleId: moduleId,
                userId: uid,
              ),
            ),
          );
        } else {
          _showSummaryPopup(context, name, moduleId, summaryPoints, fileUrl);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 80, height: 80, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black)),
              Transform.translate(
                offset: const Offset(-4, -4),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: islandColor, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2.5)),
                  child: Center(child: Icon(islandIcon, size: 34, color: isLocked ? Colors.black38 : Colors.black)),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLocked ? const Color(0xFF64748B) : (isQuiz ? const Color(0xFFFDE047) : Colors.white),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(badgeText, style: GoogleFonts.spaceGrotesk(fontSize: 8, fontWeight: FontWeight.w900, color: isLocked ? Colors.white : Colors.black)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLocked ? const Color(0xFFE2E8F0) : Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: isLocked ? null : const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
            ),
            child: Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: isLocked ? Colors.black38 : Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSummaryPopup(BuildContext context, String title, String moduleId, List<dynamic> points, String? fileUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFEF08A),
        shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.black, width: 3)),
        title: Text("RINGKASAN: $title", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: points.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("⚡ ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(points[i].toString(), style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),
            ),
          ),
        ),
        actions: [
  if (fileUrl != null && fileUrl.isNotEmpty)
    GestureDetector(
      onTap: () async {
        // Langsung buka di browser
        final Uri url = Uri.parse(fileUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal membuka modul")),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8), // Warna biru senada aksen
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_browser, color: Colors.white, size: 16),
            const SizedBox(width: 5),
            Text("BACA PDF", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    ),
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);

              // FIX: Update modul dulu, baru ambil snapshot
              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .collection('modules')
                  .doc(moduleId)
                  .update({'is_completed': true});

              // Ambil snapshot SETELAH update selesai agar count akurat
              final modulesSnapshot = await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .collection('modules')
                  .get();

              final totalModules = modulesSnapshot.docs.length;
              final completedModules = modulesSnapshot.docs
                  .where((doc) => doc.data()['is_completed'] == true)
                  .length;
              final int newProgress = totalModules > 0
                  ? ((completedModules / totalModules) * 100).toInt()
                  : 0;

              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .update({'progress': newProgress});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
              ),
              child: Text("PAHAM!", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrutalAppBar(BuildContext context, Map<String, dynamic> theme) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme['primary'],
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(theme['subtitle'].toString().toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white70)),
                  Text(courseName.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.redAccent, border: Border.all(color: Colors.black, width: 3)),
        child: const Text("BELUM ADA DATA", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 1;
    const double step = 20;
    for (double i = 0; i < size.width; i += step) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += step) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CombinedRoutePainter extends CustomPainter {
  final int totalItems;
  CombinedRoutePainter({required this.totalItems});

  @override
  void paint(Canvas canvas, Size size) {
    if (totalItems <= 1) return;
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    double rowHeight = size.height / totalItems;
    double startX = size.width * 0.5 + (size.width * 0.5 * -0.6);
    double startY = rowHeight * 0.5;
    path.moveTo(startX, startY);
    for (int i = 0; i < totalItems - 1; i++) {
      double currentBias = (i % 4 == 0) ? -0.6 : ((i % 4 == 1 || i % 4 == 3) ? 0.0 : 0.6);
      int nextIndex = i + 1;
      double nextBias = (nextIndex % 4 == 0) ? -0.6 : ((nextIndex % 4 == 1 || nextIndex % 4 == 3) ? 0.0 : 0.6);
      double x1 = size.width * 0.5 + (size.width * 0.5 * currentBias);
      double y1 = (i * rowHeight) + (rowHeight * 0.5);
      double x2 = size.width * 0.5 + (size.width * 0.5 * nextBias);
      double y2 = (nextIndex * rowHeight) + (rowHeight * 0.5);
      path.cubicTo(x1, y1 + (rowHeight * 0.4), x2, y2 - (rowHeight * 0.4), x2, y2);
    }
    final dashPath = Path();
    for (var p in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < p.length) {
        dashPath.addOval(Rect.fromCircle(center: p.getTangentForOffset(distance)!.position, radius: 2.5));
        distance += 12;
      }
    }
    canvas.drawPath(dashPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CombinedRoutePainter oldDelegate) => oldDelegate.totalItems != totalItems;
}