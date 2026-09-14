import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prestasi/screens/main_navigation_screen.dart'; // Import MainNavigationScreen

class OnboardingScreen extends StatefulWidget {
  final User user;
  const OnboardingScreen({super.key, required this.user});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _prodiController = TextEditingController();
  final _kelasController = TextEditingController(); 
  
  String _nim = "";
  String _angkatan = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ekstrakDataEmail();
  }

  void _ekstrakDataEmail() {
    String email = widget.user.email ?? "";
    final RegExp nimRegex = RegExp(r'^\d+');
    final match = nimRegex.firstMatch(email);

    if (match != null) {
      _nim = match.group(0)!;
      if (_nim.length >= 2) {
        _angkatan = _nim.substring(0, 2);
      }
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String domain = widget.user.email!.split('@')[1];

      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
          'uid': widget.user.uid,
          'displayName': widget.user.displayName,
          'nim': _nim,
          'angkatan': _angkatan,
          'email': widget.user.email,
          'photoUrl': widget.user.photoURL,
          'prodi': _prodiController.text,
          'kelas': _kelasController.text,
          'campusDomain': domain, 
          'joinedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        
        // FIX: Pindah ke MainNavigationScreen agar Bottom Navigation tersedia
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error simpan data: $e")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FBEF), 
      appBar: AppBar(
        title: const Text("Lengkapi Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4), 
                      decoration: const BoxDecoration(
                        color: Colors.green, 
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage(widget.user.photoURL ?? ""),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.user.displayName ?? "Mahasiswa",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D2A1C)),
                    ),
                    Text(
                      "NIM: $_nim | Angkatan: 20$_angkatan", 
                      style: const TextStyle(color: Color(0xFF5A7A6A), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              _buildReadOnlyField("NIM (Otomatis)", _nim),
              const SizedBox(height: 15),
              _buildReadOnlyField("ANGKATAN (Otomatis)", "20$_angkatan"),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Divider(thickness: 1),
              ),

              _buildInputField(
                controller: _prodiController,
                label: "PROGRAM STUDI",
                hint: "Contoh: Informatika",
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                controller: _kelasController,
                label: "KELAS",
                hint: "Contoh: IF B Siang",
                icon: Icons.meeting_room_outlined,
              ),

              const SizedBox(height: 40),
              
              _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E7D4E)))
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E7D4E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text(
                        "Masuk ke Dashboard", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7A9689))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E4D3E))),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7A9689))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF1E7D4E), size: 22),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          validator: (v) => v!.isEmpty ? "Bagian ini tidak boleh kosong" : null,
        ),
      ],
    );
  }
}