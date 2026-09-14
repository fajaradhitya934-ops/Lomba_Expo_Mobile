import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  
  XFile? _imageFile;
  bool _isUploading = false;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _currentPhotoUrl = _user?.photoURL;
  }

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (selected != null) {
      setState(() {
        _imageFile = selected;
      });
    }
  }

  Future<void> _uploadAndSavePhoto() async {
    if (_imageFile == null || _user == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${_user!.uid}.jpg');

      if (kIsWeb) {
        final bytes = await _imageFile!.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        await storageRef.putFile(File(_imageFile!.path));
      }

      String downloadUrl = await storageRef.getDownloadURL();

      await _user!.updatePhotoURL(downloadUrl);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'photoUrl': downloadUrl, 'photoUrl_fallback': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diperbarui! 🎉")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunggah foto: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color greenPrimary = Color(0xFF1E7D4E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      appBar: AppBar(
        title: Text(
          "Ubah Foto Profil", 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)
        ),
        backgroundColor: greenPrimary,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: greenPrimary, width: 3),
                    ),
                    child: ClipOval(
                      child: _imageFile != null
                          ? (kIsWeb
                              ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                              : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                          : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                              ? Image.network(
                                  _currentPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.person, size: 70, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, size: 70, color: Colors.grey),
                                )),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: const CircleAvatar(
                        backgroundColor: greenPrimary,
                        radius: 20,
                        child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Ketuk ikon kamera untuk memilih foto",
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(color: greenPrimary),
                  SizedBox(height: 12),
                  Text("Sedang mengunggah ke server...", style: TextStyle(color: Colors.grey)),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _imageFile != null ? _uploadAndSavePhoto : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "Simpan Perubahan", 
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}