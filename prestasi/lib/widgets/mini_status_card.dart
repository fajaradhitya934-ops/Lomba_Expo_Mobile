import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MiniStatusCard extends StatelessWidget {
  final String value;
  final String label;

  const MiniStatusCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFF1FBEF), borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E7D4E))),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF5A7A6A), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}