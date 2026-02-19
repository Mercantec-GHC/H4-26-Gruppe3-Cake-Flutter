import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../services/quiz_service.dart';
import '../widgets/quiz_dialog.dart';

class QuizPage extends StatefulWidget {
  final String userId;

  const QuizPage({super.key, required this.userId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizQuestion> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizQuestions();
  }

  /// Fetch quiz questions from API for this user
  Future<void> _loadQuizQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await QuizService.fetchUserQuiz(widget.userId);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Open quiz dialog if questions are available
  void _showQuizDialog() {
    if (_questions.isEmpty) {
      _showErrorDialog('Ingen quiz spørgsmål tilgængelige');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizDialog(
        questions: _questions,
        userId: widget.userId,
        onComplete: _onQuizComplete,
      ),
    );
  }

  /// Display match percentage and pass/fail result after quiz submission
  void _onQuizComplete(QuizResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.passed ? 'Du bestod! 🎉' : 'Du bestod ikke'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${result.matchPercent}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: result.passed ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 10),
            Text(
              result.passed
                  ? 'Du matcher godt med denne bruger!'
                  : 'I matcher ikke helt, prøv en anden bruger',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fejl'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: _buildBody(),
      ),
    );
  }

  /// Build UI states: loading, error, no questions, or start quiz button
  Widget _buildBody() {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 20),
          Text('Indlæser quiz spørgsmål...'),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 20),
          Text('Fejl ved indlæsning af quiz'),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadQuizQuestions,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('Prøv igen'),
          ),
        ],
      );
    }

    if (_questions.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, size: 60, color: Colors.grey),
          SizedBox(height: 20),
          Text('Ingen quiz spørgsmål tilgængelige'),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.quiz, size: 80, color: Colors.purple),
        SizedBox(height: 20),
        Text(
          'Klar til at tage quizzen?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Du har ${_questions.length} spørgsmål at besvare',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: _showQuizDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          child: Text(
            'Start Quiz',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}