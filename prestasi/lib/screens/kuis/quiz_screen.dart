import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String userId;

  const QuizScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.userId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  String _selectedAnswer = "";
  int _correctAnswers = 0;
  bool _isQuizFinished = false;

  Timer? _timer;
  int _remainingSeconds = 1800; // 30 menit

  late Future<DocumentSnapshot> _quizFuture;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _quizFuture = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('modules')
        .doc(widget.moduleId)
        .get();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<Map<String, int>> _processResults(int totalQuestions) async {
    int academicScore = ((_correctAnswers / totalQuestions) * 100).round();
    bool isPerfect = (_correctAnswers == totalQuestions);
    int pointsEarned = (_correctAnswers * 5) + (isPerfect ? 10 : 0);

    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final quizKey = "${widget.courseId}_${widget.moduleId}";

    try {
      // FIX: Update is_completed modul dulu
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('modules')
          .doc(widget.moduleId)
          .update({'is_completed': true});

      // FIX: Ambil snapshot SETELAH update agar count akurat
      final modulesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('modules')
          .get();

      final totalModules = modulesSnapshot.docs.length;
      final completedModules = modulesSnapshot.docs
          .where((doc) => doc.data()['is_completed'] == true)
          .length;
      final int newProgress = totalModules > 0
          ? ((completedModules / totalModules) * 100).toInt()
          : 0;

      // FIX: Update progress course setelah quiz selesai
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({'progress': newProgress});

      // Update poin user (hanya sekali per quiz)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) return;

        List<dynamic> claimedQuizzes = userSnapshot.get('claimed_quizzes') ?? [];
        if (!claimedQuizzes.contains(quizKey)) {
          transaction.update(userRef, {
            'total_points': FieldValue.increment(pointsEarned),
            'claimed_quizzes': FieldValue.arrayUnion([quizKey]),
          });
        } else {
          pointsEarned = 0;
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
    }

    return {'score': academicScore, 'points': pointsEarned};
  }

  Future<void> _submitAnswer(String correctAnswer, List<dynamic> questions) async {
    if (_selectedAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih jawaban dulu!")));
      return;
    }

    if (_selectedAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase()) {
      _correctAnswers++;
    }

    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = "";
      });
    } else {
      _timer?.cancel();
      final results = await _processResults(questions.length);
      if (!mounted) return;
      setState(() {
        _isQuizFinished = true;
        _finalAcademicScore = results['score'] ?? 0;
        _finalPointsEarned = results['points'] ?? 0;
      });
    }
  }

  int _finalAcademicScore = 0;
  int _finalPointsEarned = 0;

  @override
  Widget build(BuildContext context) {
    String timerText = "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: _quizFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }
            if (!snapshot.hasData) return const Center(child: Text("Data tidak ditemukan"));

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final List<dynamic> questions = data['quiz_questions'] ?? [];

            if (_isQuizFinished) return _buildResultScreen();

            final currentQuestion = questions[_currentQuestionIndex] as Map<String, dynamic>;
            final String questionText = currentQuestion['question'] ?? "";
            final List<dynamic> options = currentQuestion['options'] ?? [];

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Bar
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _buildBadge("WAKTU: $timerText", Colors.redAccent),
                    _buildBadge("SOAL ${_currentQuestionIndex + 1}/${questions.length}", Colors.black),
                  ]),
                  const SizedBox(height: 20),
                  // Question Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC084FC),
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                    ),
                    child: Text(questionText, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  // Options List
                  Expanded(
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, idx) {
                        final option = options[idx].toString();
                        final isSelected = _selectedAnswer == option;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAnswer = option),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFDE047) : Colors.white,
                              border: Border.all(color: Colors.black, width: 2.5),
                              boxShadow: isSelected ? null : const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                            ),
                            child: Text(option, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        );
                      },
                    ),
                  ),
                  // Submit Button
                  GestureDetector(
                    onTap: () => _submitAnswer(currentQuestion['correct_answer'], questions),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.black, width: 2)),
                      child: Text(
                        _currentQuestionIndex == questions.length - 1 ? "SELESAIKAN" : "KUNCI JAWABAN",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black, width: 2)),
      child: Text(text, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("HASIL KUIS", style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Text("SKOR: $_finalAcademicScore", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
            Text(
              "POIN DIDAPAT: $_finalPointsEarned",
              style: TextStyle(fontSize: 20, color: _finalPointsEarned > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: const BoxDecoration(color: Colors.black),
                child: Text("KEMBALI", style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}