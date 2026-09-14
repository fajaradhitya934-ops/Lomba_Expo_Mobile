import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Fungsi Utama Login
  Future<String> signInWithGoogleCampus() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "cancel";

      // Validasi email
      if (!googleUser.email.endsWith('@students.satyaterrabhinneka.ac.id')) {
        await _googleSignIn.disconnect();
        return "bukan_kampus";
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Panggil helper untuk cek status
        return await checkOnboardingStatus(user.uid);
      }
      return "error";
    } catch (e) {
      print("Error login: $e");
      return "error";
    }
  }

  // 2. HELPER: Cek status onboarding (Dipakai di login & mungkin di AuthWrapper)
  Future<String> checkOnboardingStatus(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return "onboarding"; // User baru belum ada data
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};

      // Cek apakah field penting sudah ada
      bool isKelasEmpty = (userData['class'] ?? userData['kelas']) == null || (userData['class'] ?? userData['kelas']).toString().isEmpty;
      bool isProdiEmpty = (userData['studyProgram'] ?? userData['prodi']) == null || (userData['studyProgram'] ?? userData['prodi']).toString().isEmpty;

      if (isKelasEmpty || isProdiEmpty) {
        return "onboarding";
      } else {
        return "home";
      }
    } catch (e) {
      print("Error checking status: $e");
      return "home"; // Fallback aman
    }
  }

  // 3. Logika Logout (Simpan untuk fitur 3-jam logout)
  Future<void> signOutTotal() async {
    try {
      await _googleSignIn.disconnect();
      await _auth.signOut();
      print("🔄 Sesi berhasil dihapus.");
    } catch (e) {
      print("Gagal sign out: $e");
    }
  }

  Stream<QuerySnapshot> getTopTenLeaderboard() {
    return _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(10)
        .snapshots();
  }
}