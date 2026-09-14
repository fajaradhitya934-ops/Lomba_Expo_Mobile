import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProjectScreen extends StatefulWidget {
final String projectId;
final Map<String, dynamic> projectData;

const EditProjectScreen({
super.key,
required this.projectId,
required this.projectData,
});

@override
State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
late TextEditingController titleController;
late TextEditingController descController;
late TextEditingController demoController;

String _projectImageUrl = '';
bool _isLoading = false;

@override
void initState() {
super.initState();

titleController = TextEditingController(
  text: widget.projectData['title'] ?? '',
);

descController = TextEditingController(
  text: widget.projectData['description'] ?? '',
);

demoController = TextEditingController(
  text: widget.projectData['liveDemo'] ?? '',
);

_projectImageUrl =
    widget.projectData['projectImage'] ?? '';


}

@override
void dispose() {
titleController.dispose();
descController.dispose();
demoController.dispose();
super.dispose();
}

void _showImageUrlDialog() {
final urlController = TextEditingController(
text: _projectImageUrl,
);

showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Masukkan URL Gambar'),
    content: TextField(
      controller: urlController,
      decoration: const InputDecoration(
        hintText: 'https://example.com/image.jpg',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      ElevatedButton(
        onPressed: () {
          setState(() {
            _projectImageUrl =
                urlController.text.trim();
          });

          Navigator.pop(context);
        },
        child: const Text('Simpan'),
      ),
    ],
  ),
);


}

Future<void> _updateProject() async {
if (titleController.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Judul project wajib diisi'),
),
);
return;
}


setState(() {
  _isLoading = true;
});

try {
  await FirebaseFirestore.instance
      .collection('projects')
      .doc(widget.projectId)
      .update({
    'title': titleController.text.trim(),
    'description': descController.text.trim(),
    'liveDemo': demoController.text.trim(),
    'projectImage': _projectImageUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project berhasil diperbarui'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Gagal update project: $e'),
    ),
  );
}

if (mounted) {
  setState(() {
    _isLoading = false;
  });
}

}

Widget _buildInputField({
required String label,
required TextEditingController controller,
String? hint,
}) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: GoogleFonts.plusJakartaSans(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 8),
TextField(
controller: controller,
decoration: InputDecoration(
hintText: hint,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
],
);
}

@override
Widget build(BuildContext context) {
const primaryColor = Color(0xFF4F46E5);

return Scaffold(
  appBar: AppBar(
    title: const Text('Edit Project'),
  ),
  body: _isLoading
      ? const Center(
          child: CircularProgressIndicator(),
        )
      : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Project Thumbnail',
                style:
                    GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _showImageUrlDialog,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(),
                    image: _projectImageUrl
                            .isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(
                              _projectImageUrl,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _projectImageUrl
                          .isEmpty
                      ? const Center(
                          child: Icon(
                            Icons
                                .add_photo_alternate_outlined,
                            size: 50,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              _buildInputField(
                label: 'Project Title',
                controller: titleController,
                hint: 'Masukkan judul project',
              ),

              const SizedBox(height: 24),

              Text(
                'Description',
                style:
                    GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: descController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'Describe your project...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildInputField(
                label: 'Live Demo',
                controller: demoController,
                hint: 'https://...',
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryColor,
                  ),
                  onPressed: _updateProject,
                  child: const Text(
                    'Update Project',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
);
}
}
