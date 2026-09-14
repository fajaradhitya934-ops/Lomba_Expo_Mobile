import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi untuk menyimpan data proyek ke Firestore
  Future<void> publishProject({
    required String title,
    required String category,
    required String description,
    required bool isPublic,
    // Kamu bisa tambah parameter lain seperti githubUrl nanti
  }) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw "User tidak terautentikasi";

      await _db.collection('projects').add({
        'userId': uid,
        'title': title,
        'category': category,
        'description': description,
        'isPublic': isPublic,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow; // Lempar error agar bisa ditangkap di UI
    }
  }
}