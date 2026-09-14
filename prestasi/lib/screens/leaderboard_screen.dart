import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final AuthService _authService = AuthService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  int _currentUserRank = 0;
  int _currentUserPoints = 0;
  bool _isLoadingRank = true;

  @override
  void initState() {
    super.initState();
    _calculateMyRank();
  }

  // Menghitung peringkat asli user secara aman & hemat kuota read Firestore
  Future<void> _calculateMyRank() async {
    try {
      // 1. Ambil poin milik user aktif sekarang
      DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
      
      if (!myDoc.exists) {
        setState(() => _isLoadingRank = false);
        return;
      }

      int myPoints = myDoc.get('points') ?? 0;

      // 2. Hitung berapa user yang punya poin di atas kita
      QuerySnapshot higherUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('points', isGreaterThan: myPoints)
          .get();

      // Peringkat kita = (jumlah orang berpoin lebih tinggi) + 1
      if (mounted) {
        setState(() {
          _currentUserPoints = myPoints;
          _currentUserRank = higherUsers.docs.length + 1;
          _isLoadingRank = false;
        });
      }
    } catch (e) {
      print("Gagal menghitung peringkat otomatis: $e");
      if (mounted) {
        setState(() => _isLoadingRank = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color greenPrimary = Color(0xFF1E7D4E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Peringkat Kampus", 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)
        ),
        backgroundColor: greenPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _authService.getTopTenLeaderboard(), // Memanggil query dari AuthService
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: greenPrimary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada data peringkat."));
          }

          final topDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topDocs.length,
            itemBuilder: (context, index) {
              final userRaw = topDocs[index].data() as Map<String, dynamic>;
              String name = userRaw['name'] ?? "Mahasiswa";
              int points = userRaw['points'] ?? 0;
              String campus = userRaw['campusDomain'] ?? "USTB";
              bool isMe = topDocs[index].id == _currentUid;

              return Card(
                elevation: isMe ? 2 : 0,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: isMe ? greenPrimary : Colors.transparent, width: 1.5)
                ),
                color: isMe ? const Color(0xFFE8F5E9) : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index == 0 
                        ? Colors.amber 
                        : (index == 1 ? Colors.grey[400] : (index == 2 ? Colors.brown[300] : Colors.green[50])),
                    child: Text(
                      "${index + 1}", 
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, 
                        color: index < 3 ? Colors.white : greenPrimary
                      )
                    ),
                  ),
                  title: Text(
  name, 
  style: GoogleFonts.plusJakartaSans(
    fontWeight: isMe ? FontWeight.bold : FontWeight.w600, 
    color: const Color(0xFF0D2A1C),
  ),
),
                  subtitle: Text(campus, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                  trailing: Text("$points 🌱", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: greenPrimary, fontSize: 14)),
                ),
              );
            },
          );
        },
      ),
      
      // 📌 STICKY BOTTOM BAR: Menampilkan posisi asli user kapanpun & berapapun peringkatnya
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2A1C), 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Peringkat Kamu", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  _isLoadingRank
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _currentUserRank <= 10 ? "Masuk Top 10 🎉" : "Peringkat #$_currentUserRank",
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Total Skor", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text("$_currentUserPoints Poin", style: GoogleFonts.plusJakartaSans(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}