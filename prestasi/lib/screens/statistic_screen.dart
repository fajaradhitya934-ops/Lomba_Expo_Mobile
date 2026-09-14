import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  final AuthService _authService = AuthService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  int _myRank = 0;
  bool _isLoadingRank = true;
  
  int _latestProcessedPoints = -1;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _listenToMyRankRealTime();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenToMyRankRealTime() {
    if (_currentUid.isEmpty) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .snapshots()
        .listen((myDoc) async {
      if (!myDoc.exists) return;
      
      // Ambil poin secara aman untuk kalkulasi peringkat
      final data = myDoc.data() as Map<String, dynamic>?;
      int points = (data?['points'] ?? 0).toInt();
      
      _latestProcessedPoints = points;
      final currentTargetPoints = points;

      try {
        // Hitung peringkat secara real-time langsung dari server
        AggregateQuerySnapshot countSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('points', isGreaterThan: currentTargetPoints)
            .count()
            .get(source: AggregateSource.server);

        // Proteksi anti race-condition
        if (currentTargetPoints != _latestProcessedPoints) {
          return; 
        }

        if (mounted) {
          setState(() {
            _myRank = (countSnapshot.count ?? 0).toInt() + 1;
            _isLoadingRank = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingRank = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color greenPrimary = Color(0xFF1E7D4E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      appBar: AppBar(
        title: Text(
          "Peringkat Global", 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)
        ),
        backgroundColor: greenPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _authService.getTopTenLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: greenPrimary));
          }
          
          final topDocs = snapshot.data?.docs ?? [];

          if (topDocs.isEmpty) {
            return const Center(child: Text("Belum ada data peringkat."));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: topDocs.length,
            itemBuilder: (context, index) {
              final user = topDocs[index].data() as Map<String, dynamic>;
              bool isMe = topDocs[index].id == _currentUid;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isMe ? greenPrimary : Colors.grey.withOpacity(0.1))
                ),
                color: isMe ? const Color(0xFFE8F5E9) : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index < 3 ? Colors.amber.withOpacity(0.2) : Colors.green[50],
                    child: Text(
                      "${index + 1}", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: index < 3 ? Colors.orange : greenPrimary
                      )
                    ),
                  ),
                  title: Text(user['displayName'] ?? "User", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  subtitle: Text(user['campusDomain'] ?? "Kampus", style: const TextStyle(fontSize: 12)),
                  trailing: Text("${user['points'] ?? 0} 🌱", style: const TextStyle(fontWeight: FontWeight.bold, color: greenPrimary)),
                ),
              );
            },
          );
        },
      ),
      // PERBAIKAN: Dibungkus StreamBuilder agar Poin langsung real-time dari Firestore
      bottomSheet: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_currentUid).snapshots(),
        builder: (context, userSnapshot) {
          int livePoints = 0;

          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>?;
            livePoints = (data?['points'] ?? 0).toInt();
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0D2A1C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Peringkat Kamu (Global)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  _isLoadingRank 
                    ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text("#$_myRank", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Text("$livePoints Poin", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        );
      },
    ),
  );
}
}