import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bento_action_button.dart';

class HomeQuickActions extends StatefulWidget {
  final VoidCallback onScanTap;
  final VoidCallback onTukarPoinTap;
  final VoidCallback onModuleTap;

  const HomeQuickActions({
    super.key,
    required this.onScanTap,
    required this.onTukarPoinTap,
    required this.onModuleTap,
  });

  @override
  State<HomeQuickActions> createState() => _HomeQuickActionsState();
}

class _HomeQuickActionsState extends State<HomeQuickActions> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> sdgTips = [
    {
      "tag": "SDG 4: PENDIDIKAN",
      "title": "Tips Review Efektif 📚",
      "desc": "Membaca ulang modul kuliah dalam 24 jam pertama meningkatkan retensi memori.",
      "detail": "Teknik pengulangan berjarak (spaced repetition) membantu memindahkan informasi ke memori jangka panjang untuk persiapan UTS yang lebih baik.",
      "url": "https://sdgs.un.org/goals/goal4",
      "icon": Icons.lightbulb_rounded,
    },
    {
      "tag": "SDG 12: KONSUMSI BIJAK",
      "title": "Kurangi Sampah Plastik 🌿",
      "desc": "Bawa botol minum sendiri ke kampus USTB membantu mengurangi limbah plastik.",
      "detail": "Pengurangan penggunaan plastik sekali pakai adalah langkah nyata mahasiswa dalam mendukung pola konsumsi dan produksi yang bertanggung jawab.",
      "url": "https://sdgs.un.org/goals/goal12",
      "icon": Icons.eco_rounded,
    },
    {
      "tag": "SDG 3: KESEHATAN",
      "title": "Jaga Imun Saat UTS! 🩺",
      "desc": "Kurang tidur menurunkan fokus hingga 40%. Atur jam istirahatmu dengan bijak.",
      "detail": "Kesehatan fisik dan mental adalah kunci keberhasilan akademik. Pastikan tidur cukup 7-8 jam per hari.",
      "url": "https://sdgs.un.org/goals/goal3",
      "icon": Icons.health_and_safety_rounded,
    }
  ];

  void _showSdgModal(Map<String, dynamic> tip) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(tip['icon'], size: 32, color: const Color(0xFF1E7D4E)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tip['title'], 
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 12),
              Text(
                tip['detail'], 
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[700])
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7D4E), 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () async {
                    final Uri url = Uri.parse(tip['url']);
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  child: const Text("Baca Selengkapnya di Web", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1. BAGIAN AKSI CEPAT
      Text("Aksi Cepat", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D2A1C))),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: BentoActionButton(label: "Scan", icon: Icons.camera_alt_rounded, color: const Color(0xFF69F0AE), textColor: const Color(0xFF0D2A1C), onTap: widget.onScanTap)),
          const SizedBox(width: 16),
          Expanded(child: BentoActionButton(label: "Tukar Poin", icon: Icons.shopping_bag_rounded, color: Colors.white, textColor: const Color(0xFF0D2A1C), onTap: widget.onTukarPoinTap)),
        ],
      ),
      
      const SizedBox(height: 16),
      
      // 2. BAGIAN MODUL (DIPISAHKAN DARI AKSI CEPAT)
      SizedBox(
        width: double.infinity,
        child: BentoActionButton(
          label: "Kupas Tuntas Modul", 
          icon: Icons.book_rounded, 
          color: const Color(0xFFE3F2FD), 
          textColor: const Color(0xFF1565C0), 
          onTap: widget.onModuleTap
        ),
      ),

      const SizedBox(height: 24), // Memberi jarak yang cukup

      // 3. BAGIAN EDUKASI & TIPS
      Text("Edukasi & Tips", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D2A1C))),
      const SizedBox(height: 16),
      SizedBox(
        height: 150,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: sdgTips.length,
          itemBuilder: (context, index) {
            final tip = sdgTips[index];
            return GestureDetector(
              onTap: () => _showSdgModal(tip),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D2A1C), Color(0xFF1E7D4E)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)), child: Text(tip['tag'], style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF0D2A1C)))),
                      const SizedBox(height: 8),
                      Text(tip['title'], style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(tip['desc'], maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70)),
                    ])),
                    Icon(tip['icon'], size: 40, color: Colors.amber),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(sdgTips.length, (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 5,
          width: _currentPage == index ? 15 : 5,
          decoration: BoxDecoration(color: _currentPage == index ? const Color(0xFF1E7D4E) : Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(3)),
        )),
      ),
    ],
  );
}
}