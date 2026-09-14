import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BentoActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const BentoActionButton({
    super.key, 
    required this.label, 
    required this.icon, 
    required this.color, 
    required this.textColor, 
    required this.onTap
  });


 @override
Widget build(BuildContext context) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(28),
    child: Container(
      // HAPUS height: 140; agar container lebih fleksibel
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(28)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Tambahkan ini
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1), 
              shape: BoxShape.circle
            ),
            child: Icon(icon, color: textColor, size: 28), // Sedikit diperkecil
          ),
          const SizedBox(height: 12),
          Flexible( // Tambahkan ini agar teks tidak overflow
            child: Text(
              label, 
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, // Sedikit diperkecil agar lebih pas
                fontWeight: FontWeight.bold, 
                color: textColor
              ) 
            ),
          ),
        ],
      ),
    ),
  );
}
}