import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  const EditProfileScreen({super.key, this.isDarkMode = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final _auth = FirebaseAuth.instance;

  // Controller Input Teks
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _univController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _kaggleController = TextEditingController();

  // Status State
  String _selectedAvailability = 'Available';
  bool _isLoading = true;
  bool _hasChanges = false; 

  // Variabel penampung data asli database
  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Listener real-time mendeteksi ketikan
    _nameController.addListener(_checkDataChanges);
    _usernameController.addListener(_checkDataChanges);
    _roleController.addListener(_checkDataChanges);
    _bioController.addListener(_checkDataChanges);
    _whatsappController.addListener(_checkDataChanges);
    _emailController.addListener(_checkDataChanges);
    _githubController.addListener(_checkDataChanges);
    _kaggleController.addListener(_checkDataChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _roleController.dispose();
    _univController.dispose();
    _bioController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _githubController.dispose();
    _kaggleController.dispose();
    super.dispose();
  }

  // Fungsi pengecekan perubahan data
  void _checkDataChanges() {
    if (_isLoading) return;

    bool changed = 
        _nameController.text != (_originalData['displayName'] ?? '') ||
        _usernameController.text != (_originalData['username'] ?? '') ||
        _roleController.text != (_originalData['role'] ?? '') ||
        _bioController.text != (_originalData['bio'] ?? '') ||
        _selectedAvailability != (_originalData['availabilityStatus'] ?? 'Available') ||
        _whatsappController.text != (_originalData['whatsappNumber'] ?? '') ||
        _emailController.text != (_originalData['emailAddress'] ?? '') ||
        _githubController.text != (_originalData['githubUrl'] ?? '') ||
        _kaggleController.text != (_originalData['kaggleUrl'] ?? '');

    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String universityName = await _profileService.getUniversityName(user.email);
    _univController.text = universityName;

    final data = await _profileService.getUserProfile(user.uid);

    if (data != null) {
      final contact = data['contact'] as Map<String, dynamic>? ?? {};
      
      _originalData = {
        'displayName': data['displayName'] ?? user.displayName ?? '',
        'username': data['username'] ?? '',
        'role': data['role'] ?? '',
        'bio': data['bio'] ?? '',
        'availabilityStatus': data['availabilityStatus'] ?? 'Available',
        'whatsappNumber': contact['whatsappNumber'] ?? '',
        'emailAddress': contact['emailAddress'] ?? user.email ?? '',
        'githubUrl': contact['githubUrl'] ?? '',
        'kaggleUrl': contact['kaggleUrl'] ?? contact['optionalLink'] ?? contact['optionalUrl'] ?? '', 
      };

      setState(() {
        _nameController.text = _originalData['displayName'];
        _usernameController.text = _originalData['username'];
        _roleController.text = _originalData['role'];
        _bioController.text = _originalData['bio'];
        _selectedAvailability = _originalData['availabilityStatus'];
        _whatsappController.text = _originalData['whatsappNumber'];
        _emailController.text = _originalData['emailAddress'];
        _githubController.text = _originalData['githubUrl'];
        _kaggleController.text = _originalData['kaggleUrl']; 
        _isLoading = false;
      });
    } else {
      _originalData = {
        'displayName': user.displayName ?? '',
        'emailAddress': user.email ?? '',
        'kaggleUrl': '',
      };
      setState(() {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    if (!_hasChanges) return;

    // ================= SIKLUS VALIDASI KETAT =================
    
    // 1. Validasi Email Utama (Harus berformat email valid, bukan link media sosial)
    final String emailInput = _emailController.text.trim();
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (emailInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email Utama tidak boleh kosong!')),
      );
      return;
    }
    if (!emailRegex.hasMatch(emailInput)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format Email Utama salah! Masukkan email valid (Contoh: user@gmail.com).')),
      );
      return;
    }

    // 2. Validasi GitHub Link (Wajib mengandung domain github.com jika diisi)
    final String githubInput = _githubController.text.trim();
    if (githubInput.isNotEmpty && !githubInput.toLowerCase().contains('github.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kolom GitHub harus berupa link GitHub valid! (Contoh: https://github.com/username)')),
      );
      return;
    }

    // ========================================================

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      await _profileService.updateUserProfile(
        userId: uid,
        displayName: _nameController.text,
        username: _usernameController.text,
        role: _roleController.text,
        bio: _bioController.text,
        availabilityStatus: _selectedAvailability,
        contact: {
          'whatsappNumber': _whatsappController.text,
          'whatsappActive': true,
          'emailAddress': emailInput,
          'emailActive': true,
          'githubUrl': githubInput,
          'githubActive': true,
          'kaggleUrl': _kaggleController.text, 
          'optionalLink': _kaggleController.text, 
          'kaggleActive': _kaggleController.text.isNotEmpty,
        },
      );

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context, true); // Mengirim callback true agar halaman profil ter-refresh otomatis
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFFCF8FF); 
    final Color fieldColor = widget.isDarkMode ? const Color(0xFF161B22) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final Color labelColor = widget.isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6);
    final Color borderColor = widget.isDarkMode ? const Color(0xFF30363D) : const Color(0xFFC7C4D8).withOpacity(0.5);

    const Color buttonPrimaryColor = Color(0xFF3525CD);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile', 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: buttonPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Dasar', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInputField('Nama Lengkap', _nameController, Icons.person_outline, fieldColor, textColor, labelColor, borderColor, enabled: false),
                  _buildInputField('Username', _usernameController, Icons.alternate_email, fieldColor, textColor, labelColor, borderColor),
                  _buildInputField('Role / Pekerjaan (Contoh: Mobile Developer)', _roleController, Icons.terminal, fieldColor, textColor, labelColor, borderColor),
                  _buildInputField('Universitas (Otomatis Terbaca)', _univController, Icons.school_outlined, fieldColor, textColor.withOpacity(0.5), labelColor, borderColor, enabled: false),
                  _buildInputField('Bio Deskripsi', _bioController, Icons.article_outlined, fieldColor, textColor, labelColor, borderColor, maxLines: 3),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedAvailability,
                      dropdownColor: fieldColor,
                      style: GoogleFonts.plusJakartaSans(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fieldColor,
                        labelText: 'Status Ketersediaan',
                        labelStyle: GoogleFonts.plusJakartaSans(color: labelColor),
                        prefixIcon: Icon(Icons.lens_rounded, size: 12, color: textColor),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textColor)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Available', 'Busy', 'Offline'].map((status) {
                        return DropdownMenuItem(
                          value: status, 
                          child: Text(status, style: GoogleFonts.plusJakartaSans(color: textColor)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedAvailability = val;
                          });
                          _checkDataChanges(); 
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Divider(color: borderColor),
                  const SizedBox(height: 12),
                  
                  Text(
                    'Kontak & Media Sosial', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInputField('No. WhatsApp (Tanpa +62 / 0, Contoh: 812xxxx)', _whatsappController, Icons.phone, fieldColor, textColor, labelColor, borderColor),
                  _buildInputField('Email Utama', _emailController, Icons.mail_outline, fieldColor, textColor, labelColor, borderColor),
                  _buildInputField('GitHub Username / Link', _githubController, Icons.code, fieldColor, textColor, labelColor, borderColor),
                  _buildInputField('Link (Opsional)', _kaggleController, Icons.analytics_outlined, fieldColor, textColor, labelColor, borderColor),

                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges ? buttonPrimaryColor : (widget.isDarkMode ? Colors.white12 : Colors.grey[300]),
                        elevation: _hasChanges ? 2 : 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _hasChanges ? _saveProfileData : null,
                      child: Text(
                        'Simpan Perubahan', 
                        style: GoogleFonts.plusJakartaSans(
                          color: _hasChanges ? Colors.white : (widget.isDarkMode ? Colors.white38 : Colors.grey[600]), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField(
    String label, 
    TextEditingController controller, 
    IconData icon, 
    Color fillColor, 
    Color txtColor, 
    Color lblColor, 
    Color brdColor, 
    {int maxLines = 1, bool enabled = true}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        style: GoogleFonts.plusJakartaSans(
          color: enabled ? txtColor : txtColor.withOpacity(0.5)
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled ? fillColor : fillColor.withOpacity(0.5),
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(color: lblColor),
          prefixIcon: Icon(icon, color: txtColor),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: brdColor.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: brdColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: txtColor)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}