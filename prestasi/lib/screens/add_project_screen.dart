import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart'; 

class AddProjectScreen extends StatefulWidget {
  @override
  _AddProjectScreenState createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  // 1. Inisialisasi Firebase Service
  final FirebaseService _firebaseService = FirebaseService();

  // Controller untuk mengambil data dari input
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  // State untuk Dropdown dan Switch
  String? _selectedCategory;
  bool _isPublic = true;
  bool _isLoading = false; // Untuk indikator loading saat upload

  // 2. Fungsi untuk handle Publish
  Future<void> _handlePublish() async {
    if (_titleController.text.isEmpty || _selectedCategory == null || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua kolom!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.publishProject(
        title: _titleController.text,
        category: _selectedCategory!,
        description: _descController.text,
        isPublic: _isPublic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyek Berhasil di-Publish!')),
        );
        Navigator.pop(context); // Kembali ke Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF464555)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Project',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF3525CD),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePublish, // Hubungkan fungsi
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Publish'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project Thumbnail', style: _labelStyle()),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7C4D8), width: 2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF777587)),
                  Text('Upload Cover Image', style: TextStyle(color: Color(0xFF777587))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField("Project Title", "Enter academic project name", _titleController),
            
            Text('Category', style: _labelStyle()),
            const SizedBox(height: 8),
            _buildDropdown(), // Dropdown sekarang bisa berubah value-nya
            
            const SizedBox(height: 20),
            _buildTextField("Description", "Describe objective, methodology...", _descController, maxLines: 4),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visibility', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Public projects appear on your profile'),
              trailing: Switch(
                value: _isPublic,
                onChanged: (val) => setState(() => _isPublic = val),
                activeColor: const Color(0xFF3525CD),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handlePublish, // Hubungkan fungsi
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.publish),
                label: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publish Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF464555));

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC7C4D8))),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC7C4D8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory, // Nilai yang terpilih
          hint: const Text("Select category"),
          items: ["Research", "Software", "UI/UX", "Data Analysis"].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedCategory = newValue; // Update state saat dipilih
            });
          },
        ),
      ),
    );
  }
}