import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;


class AddProjectScreen extends StatefulWidget {
  final bool isDarkMode; 
  const AddProjectScreen({super.key, this.isDarkMode = false});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _demoController = TextEditingController();
  
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _demoController.dispose();
    super.dispose();
  }



  Future<void> _pickImage() async {
  final picker = ImagePicker();

  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();

    setState(() {
      _imageBytes = bytes;
    });
  }
}

Future<String> _uploadImageToCloudinary() async {
  if (_imageBytes == null) return '';

  const cloudName = 'dedqd3ixi';
  const uploadPreset = 'prestasi_upload';

  final uri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  final request = http.MultipartRequest('POST', uri);

  request.fields['upload_preset'] = uploadPreset;

  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      _imageBytes!,
      filename: 'project.jpg',
    ),
  );

  final response = await request.send();

  if (response.statusCode == 200) {
    final responseData =
        jsonDecode(await response.stream.bytesToString());

    return responseData['secure_url'];
  } else {
    throw Exception('Upload gagal ke Cloudinary');
  }
}

  Future<void> _uploadProject() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  setState(() {
    _isLoading = true;
  });

  try {

    // UPLOAD GAMBAR KE FIREBASE STORAGE
    final imageUrl = await _uploadImageToCloudinary();

    // SIMPAN DATA PROJECT
    await FirebaseFirestore.instance
        .collection('projects')
        .add({
      'uid': user.uid,
      'authorName': user.displayName ?? 'Anonymous',
      'authorEmail': user.email,
      'authorPhoto': user.photoURL ?? '',

      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'liveDemo': _demoController.text.trim(),

      // URL GAMBAR DARI STORAGE
      'projectImage': imageUrl,

      'likes': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);

  } catch (e) {
    print(e);
  }

  setState(() {
    _isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    // ================= KONFIGURASI TEMA JELAS & GELAP =================
    final bool isDark = widget.isDarkMode;
    
    final Color bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC);
    final Color appBarColor = isDark ? const Color(0xFF161B22) : const Color(0xFFFCF8FF);
    final Color cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final Color thumbnailBgColor = isDark ? const Color(0xFF21262D) : const Color(0xFFEEF2FF);
    final Color borderStyleColor = isDark ? const Color(0xFF30363D) : const Color(0xFFC7C4D8);
    
    final Color textColor = isDark ? Colors.white : const Color(0xFF1B1B24);
    final Color textVariantColor = isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF777587);

    const Color primaryColor = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Project',
          style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        // PENYEDERHANAAN BOTTOM LINE BAR (ANTI ERROR)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            width: double.infinity,
            color: primaryColor,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Project Thumbnail', textVariantColor),
                const SizedBox(height: 8),
                
                // Area upload gambar interaktif (Mendukung Dark Mode)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: thumbnailBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? borderStyleColor : const Color(0xFFC7D2FE), width: 2),
                      image: _imageBytes != null
    ? DecorationImage(
        image: MemoryImage(_imageBytes!),
        fit: BoxFit.cover,
      )
    : null,
                    ),
                  child: _imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 32, color: primaryColor),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Project Thumbnail', 
                                style: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14)
                              ),
                              Text(
                                'Klik untuk memilih gambar dari galeri', 
                                style: GoogleFonts.plusJakartaSans(color: textVariantColor, fontSize: 10)
                              ),
                            ],
                          )
                        : Container(
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(6)),
                              child: Text('Ubah Gambar', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Project Identity', textVariantColor),
                const SizedBox(height: 12),
                _buildInputField(
                  label: 'Project Title *', 
                  controller: _titleController, 
                  hint: 'Masukkan judul project',
                  textColor: textColor,
                  cardColor: cardColor,
                  borderColor: borderStyleColor,
                  hintColor: textVariantColor
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Description', textVariantColor),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: GoogleFonts.plusJakartaSans(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Describe your project in detail...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: textVariantColor),
                    fillColor: cardColor,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderStyleColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderStyleColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Links', textVariantColor),
                const SizedBox(height: 12),
                _buildInputField(
                  label: 'Live Demo', 
                  controller: _demoController, 
                  hint: 'https://...',
                  textColor: textColor,
                  cardColor: cardColor,
                  borderColor: borderStyleColor,
                  hintColor: textVariantColor
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: isDark ? 0 : 4,
                  ),
                  onPressed: _uploadProject,
                  child: Text('Upload', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2),
    );
  }

  Widget _buildInputField({
    required String label, 
    required TextEditingController controller, 
    String? hint,
    required Color textColor,
    required Color cardColor,
    required Color borderColor,
    required Color hintColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: hintColor),
            fillColor: cardColor,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
          ),
        ),
      ],
    );
  }
}