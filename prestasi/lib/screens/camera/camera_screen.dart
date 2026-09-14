import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Penting untuk Haptic Feedback
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
        await _controller!.initialize();
      }
    } catch (e) {
      debugPrint("Kamera Error: $e");
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _uploadAndProcessImage(XFile imageFile) async {
  try {
    setState(() => _isUploading = true);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://lombaexpo-production.up.railway.app/api/scan-trash'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var streamedResponse = await request.send().timeout(const Duration(seconds: 25));
    var response = await http.Response.fromStream(streamedResponse);

    if (!mounted) return;

    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      String detectedItem = jsonResult['detected_item'] ?? "Sampah";
      int pointsAwarded = jsonResult['points_awarded'] ?? 10;

      if (detectedItem.toLowerCase().contains('tidak terdeteksi')) {
        _showErrorSnackBar("Sampah tidak terdeteksi, coba foto ulang");
        return;
      }

      await _updateUserPointsInFirestore(pointsAwarded);
      HapticFeedback.heavyImpact();
      if (mounted) _showResultDialog(detectedItem, pointsAwarded);
    } else {
      _showErrorSnackBar("Gagal memproses: Error ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Upload error: $e");
    _showErrorSnackBar("Koneksi ke server gagal");
  } finally {
    if (mounted) setState(() => _isUploading = false);
  }
}

  Future<void> _updateUserPointsInFirestore(int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'points': FieldValue.increment(points),
      'totalPhotos': FieldValue.increment(1),
      'todayPoints': FieldValue.increment(points),
    }, SetOptions(merge: true));
  }

  void _showResultDialog(String item, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Berhasil!", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Terdeteksi: $item", textAlign: TextAlign.center),
            Text("Bonus: +$points Poin 🌱", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup Dialog
              Navigator.pop(context); // Kembali ke Home
            },
            child: const Text("Kembali ke Home"),
          )
        ],
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Tampilan Kamera yang Presisi
          if (_controller != null && _controller!.value.isInitialized)
            Center(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ),

          // Tombol Kembali
          Positioned(
            top: 40, left: 20,
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),

          // Bottom Bar
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: IconButton(
                        icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                        onPressed: () async {
                          final file = await _picker.pickImage(source: ImageSource.gallery);
                          if (file != null) _uploadAndProcessImage(file);
                        },
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final file = await _controller!.takePicture();
                      _uploadAndProcessImage(file);
                    },
                    child: Container(
                      height: 70, width: 70,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isUploading) const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}