import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'course_map_screen.dart';
import 'package:prestasi/screens/main_navigation_screen.dart';
import 'package:prestasi/widgets/custom_eco_dock.dart';

class ModuleListScreen extends StatefulWidget {
  final bool isLecturer;
  const ModuleListScreen({super.key, this.isLecturer = false});

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  String selectedFilter = "Active";
  int selectedSemester = 1;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<Color> islandColors = [
    const Color(0xFF4ADE80), const Color(0xFFC084FC), const Color(0xFFFB923C),
    const Color(0xFFFDE047), const Color(0xFFFF6B6B),
  ];

  final List<IconData> islandIcons = [
    Icons.code_rounded, Icons.storage_rounded, Icons.web_rounded,
    Icons.security_rounded, Icons.phone_android_rounded,
  ];

  Future<void> _handleRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6),
      bottomNavigationBar: CustomEcoDock(
        currentIndex: 0,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(initialIndex: index),
            ),
          );
        },
        onScanTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(initialIndex: 0),
          ),
        ),
        onDiscoverTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(initialIndex: 0),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('courses').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error koneksi: ${snapshot.error}"));
              }

              final allCourses = snapshot.data?.docs ?? [];

              final filteredCourses = allCourses.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return false;

                final status = (data['status'] ?? 'Active').toString();
                final rawSem = data['semester'];
                final sem = (rawSem is num) ? rawSem.toInt() : 1;

                return status == selectedFilter && sem == selectedSemester;
              }).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildGameHeader(),
                  const SizedBox(height: 20),
                  _buildSemesterDropdown(),
                  const SizedBox(height: 16),
                  _buildGameFilterTabs(),
                  const SizedBox(height: 24),
                  Text(
                    "PILIH MATA KULIAH",
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  filteredCourses.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text("Belum ada matkul di semester ini."),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = filteredCourses[index];
                            final data = course.data() as Map<String, dynamic>?;

                            if (data == null) return const SizedBox();

                            final String name = (data['name'] ?? data['nama'] ?? "Unnamed Course").toString();
                            final int progress = (data['progress'] is num) ? (data['progress'] as num).toInt() : 0;
                            final int kuis = (data['total_kuis'] is num) ? (data['total_kuis'] as num).toInt() : 0;

                            return _buildAdventureIslandCard(
                              context,
                              courseId: course.id,
                              courseName: name,
                              progress: progress,
                              kuisCount: kuis,
                              islandColor: islandColors[index % islandColors.length],
                              islandIcon: islandIcons[index % islandIcons.length],
                              levelNumber: index + 1,
                            );
                          },
                        ),
                  const SizedBox(height: 50),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCounter(String courseId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }
        return Text(
          "$count MATERI  • ",
          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _buildGameHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUid).snapshots(),
      builder: (context, snapshot) {
        int xp = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['points'] is num) xp = (data['points'] as num).toInt();
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.5),
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFC084FC),
                    child: Icon(Icons.videogame_asset_rounded, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PLAYER: FAJAR",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "LEVELING SEKARANG!",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE047),
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
                  const SizedBox(width: 2),
                  Text(
                    "$xp XP",
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSemesterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedSemester,
          isExpanded: true,
          items: List.generate(8, (i) => i + 1)
              .map((val) => DropdownMenuItem(
                    value: val,
                    child: Text(
                      "SEMESTER $val",
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => selectedSemester = val);
          },
        ),
      ),
    );
  }

  Widget _buildGameFilterTabs() {
    return Row(
      children: ["Active", "Pending", "Completed"].map((tab) {
        final isSelected = selectedFilter == tab;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => selectedFilter = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
                border: Border.all(color: Colors.black, width: 2.5),
              ),
              child: Text(
                tab.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdventureIslandCard(
    context, {
    required courseId,
    required courseName,
    required progress,
    required kuisCount,
    required islandColor,
    required islandIcon,
    required levelNumber,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 45),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseMapScreen(
                    courseId: courseId,
                    courseName: courseName,
                  ),
                ),
              ),
              child: Container(
                height: 110,
                decoration: const BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: Container(
                  padding: const EdgeInsets.only(left: 55, right: 16, top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              courseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "PROGRESS: $progress%  •  ",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildModuleCounter(courseId),
                                Text(
                                  "$kuisCount KUIS",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: islandColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: islandColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.5),
              ),
              child: Center(child: Icon(islandIcon, size: 38, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}