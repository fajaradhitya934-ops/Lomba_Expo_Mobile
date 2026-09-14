import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isLogoHovered = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() { _isLoading = true; });
    try {
      // PERBAIKAN UTAMA: Hapus hostedDomain agar jendela pemilih akun bawaan Chrome muncul kembali
      final GoogleSignIn googleSignInInstance =
    GoogleSignIn(
      scopes: [
        'email',
      ],
    );
      final GoogleSignInAccount? googleUser = await googleSignInInstance.signIn();

      if (googleUser == null) {
        setState(() { _isLoading = false; });
        return;
      }

      // VALIDASI: Di sini kita filter secara mandiri setelah user memilih akunnya
      if (!googleUser.email.endsWith('.ac.id')) {
        await googleSignInInstance.signOut(); // Keluarkan paksa sesi email non-ac.id
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akses ditolak! Wajib menggunakan email institusi dengan akhiran .ac.id'),
              backgroundColor: Color(0xFFBA1A1A),
            ),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }

      // Ambil kredensial otentikasi untuk dikirim ke Firebase
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Jalankan navigasi langsung ke halaman Discover jika valid
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/discover');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eror: $e'), backgroundColor: const Color(0xFFBA1A1A)),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3525CD);
    const Color primaryContainer = Color(0xFF4F46E5);
    const Color onSurface = Color(0xFF1B1B24);
    const Color onSurfaceVariant = Color(0xFF464555);
    const Color outlineVariant = Color(0xFFC7C4D8);
    const Color outline = Color(0xFF777587);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFCF8FF),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x0D00687A),
              Color(0xFFFCF8FF),
              Color(0x144F46E5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // ================= TOP DECORATIVE HEADER =================
                  Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isLogoHovered = true),
                          onTapUp: (_) => setState(() => _isLogoHovered = false),
                          onTapCancel: () => setState(() => _isLogoHovered = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isLogoHovered
                                  ? [BoxShadow(color: onSurface.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))]
                                  : [BoxShadow(color: onSurface.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(
                              Icons.school_rounded, 
                              color: Colors.white, 
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Prestasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                            letterSpacing: -0.02,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome to Prestasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Build your academic legacy.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ================= LOGIN ACTION AREA =================
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: outlineVariant, width: 1),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x1E293B).withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryContainer),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'G',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF4285F4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Sign in with Google',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Divider (OR)
                      Row(
                        children: [
                          Expanded(child: Divider(color: outlineVariant.withValues(alpha: 0.5), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'OR',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: outlineVariant.withValues(alpha: 0.5), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Secondary Email Option
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Continue with Email',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New here? ',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVariant),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Create an account',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ================= FOOTER LINKS & HOME INDICATOR =================
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Terms of Service',
                              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: onSurfaceVariant.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(width: 12),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: outlineVariant, shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Text(
                              'Privacy Policy',
                              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: onSurfaceVariant.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Home Indicator Bar
                        Container(
                          width: 128,
                          height: 6,
                          decoration: BoxDecoration(
                            color: onSurface.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}