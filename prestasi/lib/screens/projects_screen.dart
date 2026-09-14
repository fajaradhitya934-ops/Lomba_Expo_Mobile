import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3525CD);
    const Color backgroundColor = Color(0xFFFCF8FF);
    const Color onSurfaceVariant = Color(0xFF464555);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBWl-ZPRkiBse_w4-iKx6jdDXBveJu4fYhW84As8diaz9RduaVScErDek4zLHsb2cofVyBV2yKRqu8ZjqRpJYJGYfWKy8GPxtH8WvpvMilov-MMz5c8tRET9mud2gX968aGyYmHUI05jp14s0jH6vFzPkfD8CGkp3LzwieJgbExU3UoZxo6rTeiKlroWfE5vG40tqkpaUobpysEL32-cs7wgUXPJbwwEVM1JFtwstislY_vMlGqe8Mua0XUMCcShFZCHIyBse74bgzp'),
            ),
            const SizedBox(width: 12),
            Text(
              'My Projects',
              style: GoogleFonts.plusJakartaSans(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: primaryColor),
            onPressed: () {},
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', isSelected: true),
                _buildFilterChip('Web'),
                _buildFilterChip('Mobile'),
                _buildFilterChip('Data Science'),
                _buildFilterChip('AI/ML'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildProjectCard(
            title: 'NeuralPath Visualizer',
            description: 'An advanced interactive visualization tool for mapping deep neural network weight distributions.',
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCkeOwaJia9ahgTmC158QzVQZN1MGZbYS0PsA0uB5bPn4MUrQfnsY6AMFWFyegL0HuqJHPz6eocqQqf2531_nTPTZJ3bJX9Q9SUjPY9r4wQJvWIBBXeP7_uPi26bYZZUNLXkrELBcNslRSlrNxBP_1YpWr6cqMSKWj_p5-atzPkqIvgVvsP9cq6X8FKhCpunt8Em7sI8M6yXun5oHGLJykGmn3Kd353TMjtPDdndrEIMUVKPPbyzGwQ0EdFYc4lca_6zTgc6yz3kCS_',
            tags: ['Python', 'Jupyter', 'TensorFlow'],
            isPublic: true,
            stars: '124',
            forks: '42',
          ),
          const SizedBox(height: 12),
          _buildProjectCard(
            title: 'Campus Connect App',
            description: 'A cross-platform mobile application designed to facilitate peer-to-peer mentoring and study group formation.',
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD5WTu7eebLx18fXhPeUS4wtAA0l9cbPlcrYUbSrmjsNYFWvfRG3-IeBfkrC3cLGKWiU79dhwwmRRy9XcOy_NGaCegTQrbSzljXuDUrRH6rKWt0ALd4uo8OJTtg7ZgW3hGdSLwphhNBP5IneyRhnEMSHp11394XbYIZ9_NUKwED0GqQ9Hr79VPkpPMxSCIxV3ifA1QDGNVlO4HSxppMWmamLHzjfMrHFRKEsS1L8zVu9LfKoyahPwdPehFA2cdI4yLh1n4MPUBLoRep',
            tags: ['Flutter', 'Firebase'],
            isPublic: false,
            stars: '89',
            forks: '12',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, 
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_special), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Blog'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF3525CD) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: const Color(0xFFC7C4D8)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: isSelected ? Colors.white : const Color(0xFF464555),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildProjectCard({
    required String title,
    required String description,
    required String imageUrl,
    required List<String> tags,
    required bool isPublic,
    required String stars,
    required String forks,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias, // FIX: overflow dipindah ke sini
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7C4D8).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover),
              Positioned( // FIX: Menghapus teks typo Jepang
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPublic 
                      ? const Color(0xFF3525CD).withValues(alpha: 0.9) 
                      : const Color(0xFF464555).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPublic ? 'PUBLIC' : 'PRIVATE',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF464555)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F2FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF3525CD))),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_outline, size: 18, color: Color(0xFF464555)),
                        const SizedBox(width: 4),
                        Text(stars, style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                        const SizedBox(width: 16),
                        const Icon(Icons.fork_right, size: 18, color: Color(0xFF464555)),
                        const SizedBox(width: 4),
                        Text(forks, style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View', style: TextStyle(color: Color(0xFF3525CD), fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}