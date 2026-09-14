  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../widgets/custom_eco_dock.dart';
  import 'home_screen.dart';
  import 'statistic_screen.dart';
  import 'package:prestasi/screens/camera/camera_screen.dart';
  import 'package:prestasi/screens/modul/ModuleListScreen.dart';
  import 'package:prestasi/screens/profile/profile_screen.dart';



  class MarketScreen extends StatefulWidget {
    const MarketScreen({super.key});

    @override
    State<MarketScreen> createState() => _MarketScreenState();
  }

  class _MarketScreenState extends State<MarketScreen> {
    final User? _user = FirebaseAuth.instance.currentUser;
    final int _currentIndex = 2; // Index 2 sesuai posisi di CustomEcoDock

    // Data reward bento
    final List<Map<String, dynamic>> _rewards = [
      {"title": "Voucher DANA Rp10k", "points": 100, "icon": Icons.account_balance_wallet, "color": Colors.blue},
      {"title": "Bibit Pohon Mangga", "points": 250, "icon": Icons.forest, "color": Colors.green},
      {"title": "Tumbler Eco-Friendly", "points": 400, "icon": Icons.local_drink, "color": Colors.orange},
      {"title": "E-Certificate Green Hero", "points": 50, "icon": Icons.workspace_premium, "color": Colors.purple},
      {"title": "Voucher GrabFood Rp25k", "points": 250, "icon": Icons.fastfood, "color": Colors.red},
    ];

    void _tukarReward(String title, int cost, int userPoints) {
      if (userPoints < cost) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Poin kamu tidak cukup untuk menukarkan reward ini! 😟"), 
            backgroundColor: Colors.red
          ),
        );
        return;
      }

      final String? uid = _user?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User tidak valid. Silakan login ulang."), backgroundColor: Colors.red),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Konfirmasi Penukaran"),
          content: Text("Apakah kamu yakin ingin menukarkan $cost poin dengan '$title'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text("Batal", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E7D4E), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () async {
                // Tutup dialog terlebih dahulu agar UI responsif
                Navigator.pop(dialogContext);
                
                try {
                  // Referensi untuk membuat dokumen acak baru di dalam koleksi 'redemptions'
                  final redemptionRef = FirebaseFirestore.instance.collection('redemptions').doc();
                  
                  // Gunakan WriteBatch supaya proses potong poin & catat transaksi sukses bersamaan
                  WriteBatch batch = FirebaseFirestore.instance.batch();

                  // 1. Potong Poin User di koleksi 'users'
                  DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
                  batch.update(userRef, {'points': userPoints - cost});

                  // 2. Tulis data riwayat transaksi secara lengkap ke koleksi 'redemptions'
                  batch.set(redemptionRef, {
                    'redemptionId': redemptionRef.id,
                    'userId': uid,
                    'userName': _user?.displayName ?? "Mahasiswa",
                    'userEmail': _user?.email,
                    'rewardTitle': title,
                    'pointsCost': cost,
                    'status': "Sukses Ditukarkan", 
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  // Eksekusi Batch ke server Firestore
                  await batch.commit();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Berhasil menukarkan $title! Riwayat transaksi telah dicatat. 🎉"),
                        backgroundColor: const Color(0xFF1E7D4E),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Gagal memproses transaksi: $e"), 
                        backgroundColor: Colors.red
                      ),
                    );
                  }
                }
              },
              child: const Text("Tukarkan", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      const Color greenDark = Color(0xFF0D2A1C);
      const Color greenPrimary = Color(0xFF1E7D4E);

      return Scaffold(
        backgroundColor: const Color(0xFFF4F9F5),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(_user?.uid).snapshots(),
          builder: (context, snapshot) {
            int currentPoints = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              currentPoints = userData['points'] ?? 0;
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Poin ala Bento besar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: greenPrimary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Poin Kamu", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text("$currentPoints Pts", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const CircleAvatar(
                            backgroundColor: Colors.white24,
                            radius: 24,
                            child: Icon(Icons.stars, color: Colors.amber, size: 30),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Tukar Reward Lingkungan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: greenDark)),
                    const SizedBox(height: 16),

                    // Susunan Bento Grid Reward
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _rewards.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final item = _rewards[index];
                        return GestureDetector(
                          onTap: () => _tukarReward(item['title'], item['points'], currentPoints),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: item['color'].withOpacity(0.1),
                                      radius: 18,
                                      child: Icon(item['icon'], color: item['color'], size: 20),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                      child: Text("${item['points']} Pts", style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item['title'],
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: greenDark),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text("Ketuk untuk tukar", style: TextStyle(fontSize: 10, color: Colors.grey))
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }