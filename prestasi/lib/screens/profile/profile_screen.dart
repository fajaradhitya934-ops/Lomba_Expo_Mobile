import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_screen.dart'; 

import 'package:prestasi/services/auth_service.dart';
import 'package:prestasi/screens/login_screen.dart';
import 'package:prestasi/screens/redemption_history_screen.dart';
import 'package:prestasi/screens/main_navigation_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    const Color greenDark = Color(0xFF0D2A1C);
    const Color greenPrimary = Color(0xFF1E7D4E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: greenPrimary));
          
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          int points = data['points'] ?? 0;
          int photos = data['totalPhotos'] ?? data['total_photos'] ?? 0;

          String kelas = data['class'] ?? data['kelas'] ?? "IF B Siang";
          String prodi = data['studyProgram'] ?? data['prodi'] ?? "Informatika";
          String angkatan = (data['year'] ?? data['angkatan'] ?? "2024").toString();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Profile
                Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
                  decoration: const BoxDecoration(
                    color: greenPrimary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white24,
                        backgroundImage: data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty 
                            ? NetworkImage(data['photoUrl']) 
                            : (_user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null),
                        child: (data['photoUrl'] == null || data['photoUrl'].toString().isEmpty) && _user?.photoURL == null 
                            ? const Icon(Icons.person, size: 50, color: Colors.white) 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(data['displayName'] ?? "User", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(_user?.email ?? "", style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Statistik Kontribusi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: greenDark)),
                      const SizedBox(height: 16),
                      
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          _buildMiniStat(Icons.spa, "$points", "Total Poin", Colors.orange),
                          _buildMiniStat(Icons.camera_alt, "$photos", "Foto Valid", Colors.blue),
                          _buildMiniStat(Icons.school, prodi, "Program Studi", Colors.purple),
                          _buildMiniStat(Icons.meeting_room, kelas, "Kelas", Colors.red),
                          _buildMiniStat(Icons.calendar_today, angkatan, "Angkatan", Colors.teal),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Text("Pengaturan Akun", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: greenDark)),
                      const SizedBox(height: 12),

                      _buildMenuTile(Icons.person_outline, "Edit Profil", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                      }),
                      
                      _buildMenuTile(Icons.history, "Riwayat Penukaran", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RedemptionHistoryScreen()),
                        );
                      }),
                      
                      _buildMenuTile(Icons.notifications_none, "Notifikasi", () {
                        // Placeholder Aksi Notifikasi
                      }),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _authService.signOutTotal();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text("Keluar Aplikasi", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ],
            ),
          );
        }, 
      ),
      // ❌ Di sini udah bersih total dari bottomNavigationBar dan floatingActionButton lama
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF1E7D4E)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap, 
    );
  }
}