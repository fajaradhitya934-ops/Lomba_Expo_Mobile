import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prestasi/services/auth_service.dart';
import 'package:prestasi/utility/SessionManager.dart';
import 'package:prestasi/screens/onboarding_screen.dart';
import 'package:prestasi/screens/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryGreen = Color(0xFF1E7D4E);
  static const Color darkText = Color(0xFF0D2A1C);
  static const Color mutedText = Color(0xFF5A7A6A);
  static const Color accentOrange = Color(0xFFE8A33D);
  static const Color accentTeal = Color(0xFF2E9760);

  static const String _logoAsset = 'lib/screens/Selko/Screens/Logo.png';

  @override
  void initState() {
    super.initState();
    _clearSessionOnLaunch();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearSessionOnLaunch() async {
    setState(() => isLoading = true);
    await _authService.signOutTotal();
    await SessionManager.clearLastActive();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // ============================================================
  // LOGIC ASLI - TIDAK DIUBAH
  // ============================================================
  void handleLogin() async {
    setState(() => isLoading = true);

    try {
      String statusRute = await _authService.signInWithGoogleCampus();

      if (mounted) {
        if (statusRute == "home") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selamat datang kembali! 🎉")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        } else if (statusRute == "onboarding") {
          User? currentUser = FirebaseAuth.instance.currentUser;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Silakan lengkapi data profil mahasiswa.")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OnboardingScreen(user: currentUser!)),
          );
        } else if (statusRute == "bukan_kampus") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Akses ditolak! Wajib menggunakan email .ac.id"),
              backgroundColor: Colors.red,
            ),
          );
        } else if (statusRute == "cancel") {
          // Tidak melakukan apa-apa
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Terjadi kesalahan sistem, silakan coba lagi."),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  // ============================================================
  // END LOGIC ASLI
  // ============================================================

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Mode ini belum tersedia, silakan gunakan Google Sign-In ya 🙂"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEAF6EE),
              const Color(0xFFFAFEFB),
              primaryGreen.withOpacity(0.10),
            ],
          ),
        ),
        child: Stack(
          children: [
            // --- BACKGROUND DECORATION ---
            Positioned(top: 36, left: 24, child: _dotGrid()),
            Positioned(
              top: 60,
              right: -10,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryGreen.withOpacity(0.22), width: 2),
                ),
              ),
            ),
            Positioned(
              top: 95,
              right: 35,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentTeal.withOpacity(0.18),
                ),
              ),
            ),
            _sparkle(top: 130, left: size.width * 0.78, color: accentOrange, size: 14),
            _sparkle(top: size.height * 0.34, left: size.width * 0.08, color: primaryGreen, size: 12),
            _sparkle(top: size.height * 0.40, right: size.width * 0.10, color: accentTeal, size: 10),

            Positioned(bottom: -16, left: -16, child: _leafCluster(flip: false)),
            Positioned(bottom: -16, right: -16, child: _leafCluster(flip: true)),

            // --- MAIN CONTENT ---
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 60),
                        child: _buildLoginCard(),
                      ),
                      Positioned(top: 0, child: _buildLogoImage()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- BACKGROUND HELPERS ----------------

  Widget _dotGrid() {
    return SizedBox(
      width: 46,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(12, (i) {
          return Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryGreen.withOpacity(0.45),
            ),
          );
        }),
      ),
    );
  }

  Widget _sparkle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Icon(Icons.auto_awesome_rounded, size: size, color: color.withOpacity(0.55)),
    );
  }

  Widget _leafCluster({required bool flip}) {
    final Widget cluster = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.eco_rounded, size: 96, color: primaryGreen.withOpacity(0.16)),
        Positioned(
          top: 8,
          left: 34,
          child: Icon(Icons.eco_rounded, size: 52, color: accentTeal.withOpacity(0.16)),
        ),
        Positioned(
          top: 44,
          left: 4,
          child: Icon(Icons.eco_rounded, size: 38, color: primaryGreen.withOpacity(0.20)),
        ),
      ],
    );

    if (!flip) return cluster;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(3.1416),
      child: cluster,
    );
  }

  // ---------------- LOGO ----------------

  Widget _buildLogoImage() {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [primaryGreen.withOpacity(0.16), Colors.transparent],
              ),
            ),
          ),
          Image.asset(
            _logoAsset,
            width: 110,
            height: 110,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // fallback kalau asset belum terdaftar di pubspec.yaml
              return Icon(Icons.auto_awesome_rounded, size: 52, color: primaryGreen);
            },
          ),
        ],
      ),
    );
  }

  // ---------------- CARD ----------------

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 80, 26, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Selamat Datang!",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Masuk dengan akun Google kampus kamu\nuntuk melanjutkan",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.5,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 28),

          isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(color: primaryGreen),
                )
              : Column(
                  children: [
                    _buildGoogleButton(),
                    const SizedBox(height: 12),
                    _buildEmailModeButton(),
                  ],
                ),

          const SizedBox(height: 22),
          _buildDivider("atau"),
          const SizedBox(height: 18),

          _buildLabel("Email atau Username"),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hint: "Masukkan email atau username",
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),

          _buildLabel("Password"),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            hint: "Masukkan password",
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: mutedText,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showComingSoon,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                "Lupa password?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _showComingSoon,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15532B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "Masuk",
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _showComingSoon,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Belum punya akun? ",
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: mutedText),
                  ),
                  TextSpan(
                    text: "Daftar sekarang",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Khusus email kampus\n@students.satyaterrabhinneka.ac.id",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: darkText.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: mutedText, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: darkText),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: mutedText, size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: mutedText.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: handleLogin, // <-- logic asli, tidak diubah
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.withOpacity(0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              "Masuk dengan Google",
              style: GoogleFonts.plusJakartaSans(
                color: darkText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailModeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _showComingSoon, // placeholder, belum ada logic email/password
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.withOpacity(0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline_rounded, size: 22, color: primaryGreen),
            const SizedBox(width: 8),
            Text(
              "Masuk dengan Email",
              style: GoogleFonts.plusJakartaSans(
                color: darkText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}