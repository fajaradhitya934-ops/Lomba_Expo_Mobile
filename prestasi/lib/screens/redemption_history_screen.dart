import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RedemptionHistoryScreen extends StatelessWidget {
  const RedemptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    const Color greenDark = Color(0xFF0D2A1C);
    const Color greenPrimary = Color(0xFF1E7D4E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      appBar: AppBar(
        title: Text(
          "Riwayat Penukaran",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: greenPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text("User tidak valid. Silakan login ulang."))
          : StreamBuilder<QuerySnapshot>(
              // Mengambil data riwayat penukaran khusus milik user yang sedang login
              stream: FirebaseFirestore.instance
                  .collection('redemptions')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: greenPrimary));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada riwayat penukaran",
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    // Format tanggal transaksi
                    String formattedDate = "-";
                    if (data['createdAt'] != null) {
                      final Timestamp timestamp = data['createdAt'] as Timestamp;
                      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate());
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: greenPrimary.withOpacity(0.1),
                            radius: 24,
                            child: const Icon(Icons.redeem, color: greenPrimary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['rewardTitle'] ?? "Reward",
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: greenDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "-${data['pointsCost']} Pts",
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data['status'] ?? "Sukses",
                                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}