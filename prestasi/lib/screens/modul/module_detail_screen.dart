import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:prestasi/controller/module_controller.dart';
import 'package:prestasi/screens/kuis/quiz_screen.dart';

class ModuleDetailScreen extends StatelessWidget {
  final String courseId;
  final String courseName;
  final String moduleId;

  const ModuleDetailScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A221E),
      appBar: AppBar(
        title: Text(courseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: ModuleController().getModuleDetail(courseId, moduleId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Gagal memuat detail materi. Sesi login terganggu atau akses ditolak.",
                  style: TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text("Data modul tidak ditemukan.", style: TextStyle(color: Colors.white60)));
          }

          // FIX: fileUrl sudah full Cloudinary URL, langsung pakai
          String fileUrl = data['fileUrl'] ?? '';
          String title = data['title'] ?? data['moduleContent'] ?? data['content'] ?? "Materi tanpa judul";

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Modul Level: ${data['levelNumber'] ?? data['order'] ?? 0}",
                        style: const TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                      const Divider(color: Colors.white24, height: 32),
                      if (fileUrl.isNotEmpty) ...[
                        const Text(
                          "Berkas Materi Tersedia:",
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: const Color(0xFF2B3630),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file, color: Color(0xFF69F0AE)),
                            title: const Text("Unduh Materi Document", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            subtitle: const Text("Klik untuk membuka PDF / Word", style: TextStyle(color: Colors.white60, fontSize: 12)),
                            trailing: const Icon(Icons.download_for_offline, color: Color(0xFF69F0AE)),
                            onTap: () async {
                              if (fileUrl.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Link berkas kosong!")),
                                );
                                return;
                              }

                              // FIX: Langsung pakai fileUrl dari Firestore (sudah full Cloudinary URL)
                              String finalUrl = fileUrl.trim();

                              if (kIsWeb) {
                                try {
                                  final web.HTMLAnchorElement anchor = web.document.createElement('a') as web.HTMLAnchorElement;
                                  anchor.href = finalUrl;
                                  anchor.target = '_blank';
                                  anchor.click();
                                  anchor.remove();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal web: $e")));
                                }
                              } else {
                                final Uri url = Uri.parse(finalUrl);
                                try {
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } else {
                                    throw 'Tidak bisa membuka $url';
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Gagal mengunduh: $e")),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF69F0AE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          courseId: courseId,
                          moduleId: moduleId,
                          userId: '',
                        ),
                      ));
                    },
                    child: const Text("Mulai Kuis", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}