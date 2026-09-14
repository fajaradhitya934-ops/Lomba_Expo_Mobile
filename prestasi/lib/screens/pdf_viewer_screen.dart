import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(pdfUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $pdfUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kita panggil otomatis saat halaman dibuka
    _launchURL();
    
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const Text("Sedang membuka PDF..."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _launchURL,
              child: const Text("Buka Kembali PDF"),
            )
          ],
        ),
      ),
    );
  }
}