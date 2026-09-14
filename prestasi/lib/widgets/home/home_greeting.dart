import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeGreeting extends StatelessWidget {
  final String name;
  final VoidCallback onProfileTap;

  const HomeGreeting({
    super.key,
    required this.name,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 28, color: const Color(0xFF0D2A1C)),
              children: [
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E7D4E)),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Mari buat kampus lebih hijau hari ini!",
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5A7A6A), fontSize: 14),
        ),
      ],
    );
  }
}