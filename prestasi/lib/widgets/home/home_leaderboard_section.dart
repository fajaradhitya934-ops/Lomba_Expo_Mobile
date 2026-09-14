import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeLeaderboardSection extends StatelessWidget {
  final String domain;
  final Color primaryColor;
  final VoidCallback onSeeAllTap;

  const HomeLeaderboardSection({
    super.key,
    required this.domain,
    required this.primaryColor,
    required this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Leaderboard",
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D2A1C)),
            ),
            InkWell(
              onTap: onSeeAllTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  "Lihat Semua",
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('campusDomain', isEqualTo: domain)
              .orderBy('points', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            var docs = snapshot.data!.docs;
            return Column(
              children: List.generate(docs.length, (index) {
                var data = docs[index].data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Text("${index + 1}", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty
                            ? NetworkImage(data['photoUrl'])
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(data['displayName'] ?? "User", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.workspace_premium, color: Colors.orange, size: 20),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}