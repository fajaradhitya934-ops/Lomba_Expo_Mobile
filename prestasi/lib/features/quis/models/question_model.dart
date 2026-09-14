class QuestionModel {
  final String id;
  final String questionText;
  final List<String> options; // Menyesuaikan dengan field 'option' di DB kamu
  final String correctAnswer;
  final int points;
  final int order;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.points,
    required this.order,
  });

  // Factory untuk merubah data dari Firestore ke object QuestionModel
  factory QuestionModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return QuestionModel(
      id: documentId,
      questionText: data['questionText'] ?? '',
      // Mengambil array dari field 'option' di DB
      options: List<String>.from(data['option'] ?? []), 
      correctAnswer: data['correctAnswer'] ?? '',
      points: data['points'] ?? 0,
      order: data['order'] ?? 0,
    );
  }
}