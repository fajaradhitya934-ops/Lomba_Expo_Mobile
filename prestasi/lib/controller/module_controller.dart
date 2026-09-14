import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mengambil daftar semua modul berdasarkan nama/ID course (Real-time Stream)
  Stream<QuerySnapshot> getModules(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('modules')
        .orderBy('order')
        .snapshots();
  }

  // Mengambil detail konten materi modul tertentu
  Future<DocumentSnapshot> getModuleDetail(String courseId, String moduleId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('modules')
        .doc(moduleId)
        .get();
  }
}