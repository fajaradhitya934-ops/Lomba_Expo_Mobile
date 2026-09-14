class ModulModel {
  final String id; // Tambahkan ID untuk referensi kuis nanti
  final int levelNumber;
  final String moduleContent;
  final String fileUrl; // URL dari Laravel
  final Map<String, dynamic> quiz;

  ModulModel({
    required this.id,
    required this.levelNumber,
    required this.moduleContent,
    required this.fileUrl,
    required this.quiz,
  });

  factory ModulModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ModulModel(
    id: id,
    levelNumber: data['levelNumber'] ?? data['order'] ?? 0, // mengambil dari order jika levelNumber kosong
    moduleContent: data['title'] ?? data['moduleContent'] ?? data['content'] ?? 'Materi tanpa judul', 
    fileUrl: data['fileUrl'] ?? '',
    quiz: data['quiz'] ?? {},
  );
  }
}