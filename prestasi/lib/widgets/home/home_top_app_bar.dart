import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTopAppBar extends StatelessWidget {
  final String photo;
  final VoidCallback onProfileTap;

  const HomeTopAppBar({
    super.key,
    required this.photo,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Spark",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF0D2A1C),
                      ),
                    ),
                    Text(
                      "Student Platform for",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        const Icon(Icons.notifications_none_rounded, size: 28),
      ],
    );
  }
}