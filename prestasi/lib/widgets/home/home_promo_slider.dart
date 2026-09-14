import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePromoSlider extends StatefulWidget {
  const HomePromoSlider({super.key});

  @override
  State<HomePromoSlider> createState() => _HomePromoSliderState();
}

class _HomePromoSliderState extends State<HomePromoSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data Edukasi & Tips berbasis SDGs
  final List<Map<String, dynamic>> sdgPromos = [
    {
      "tag": "SDG 3: KESEHATAN",
      "title": "Jaga Imun Saat UTS! 🩺",
      "desc": "Kurang tidur menurunkan fokus hingga 40%. Yuk, atur jam istirahatmu!",
      "bgGradient": [const Color(0xFF0D2A1C), const Color(0xFF1E7D4E)],
      "icon": Icons.health_and_safety_rounded,
      "iconColor": Colors.amber,
    },
    {
      "tag": "SDG 12: KONSUMSI BIJAK",
      "title": "Kurangi Sampah Plastik 🌿",
      "desc": "Bawa botol minum sendiri ke kampus USTB bisa menghemat pengeluaran sekaligus jaga bumi.",
      "bgGradient": [const Color(0xFF145334), const Color(0xFF2E7D32)],
      "icon": Icons.eco_rounded,
      "iconColor": Colors.greenAccent,
    },
    {
      "tag": "SDG 4: PENDIDIKAN",
      "title": "Tips Review Efektif 📚",
      "desc": "Membaca ulang modul kuliah dalam 24 jam pertama meningkatkan retensi memori hingga 80%.",
      "bgGradient": [const Color(0xFF1A221E), const Color(0xFF37474F)],
      "icon": Icons.lightbulb_rounded,
      "iconColor": Colors.amberAccent,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 125, // Tinggi disesuaikan agar teks deskripsi SDGs tidak terpotong
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: sdgPromos.length,
            itemBuilder: (context, index) {
              final promo = sdgPromos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: promo['bgGradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D2A1C).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tag SDG
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              promo['tag'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D2A1C),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Judul Tips
                          Text(
                            promo['title'],
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Deskripsi Detail
                          Text(
                            promo['desc'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Icon SDG
                    Icon(
                      promo['icon'], 
                      size: 45, 
                      color: promo['iconColor']
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            sdgPromos.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              width: _currentPage == index ? 15 : 5,
              decoration: BoxDecoration(
                color: _currentPage == index ? const Color(0xFF1E7D4E) : Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}