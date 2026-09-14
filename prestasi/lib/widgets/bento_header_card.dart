import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BentoHeaderCard extends StatelessWidget {
  final int points;
  final Color primaryColor;
  final int targetPoints; // Target murni pengumpulan poin

  const BentoHeaderCard({
    super.key, 
    required this.points, 
    required this.primaryColor,
    this.targetPoints = 1000, // Kita set target default ke 1000 pts
  });

  @override
  Widget build(BuildContext context) {
    // Menghitung persentase progress secara realtime (0.0 sampai 1.0)
    double progressPercent = (points / targetPoints).clamp(0.0, 1.0);

    // Format ribuan lokal (Contoh: 1.500)
    String formattedPoints = points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
    );

    // Teks info kontribusi murni, bukan naik level/pangkat
    int remainingPoints = targetPoints - points;
    String statusText = remainingPoints > 0 
        ? "Butuh $remainingPoints poin lagi untuk mencapai target"
        : "Selamat! Kamu telah mencapai target kontribusi hijau minggu ini 🌱";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBEF),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SALDO POIN ANDA", 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, 
              fontWeight: FontWeight.w800, 
              color: const Color(0xFF5A7A6A), 
              letterSpacing: 1
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedPoints, 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36, 
                  fontWeight: FontWeight.w900, 
                  color: const Color(0xFF0D2A1C)
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "pts", 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: const Color(0xFF5A7A6A)
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar Realtime
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercent, 
              backgroundColor: Colors.white, 
              color: primaryColor, 
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          
          // Keterangan Target Kontribusi Hijau
          Row(
            children: [
              const Icon(Icons.spa_rounded, color: Color(0xFF1E7D4E), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText, 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600, 
                    color: const Color(0xFF0D2A1C)
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}