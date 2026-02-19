import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../services/quiz_service.dart';

/// Shows quiz questions as a dialog overlay
class QuizDialog extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String userId;
  final Function(QuizResult) onComplete;

  const QuizDialog({
    Key? key,
    required this.questions,
    required this.userId,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  int currentQuestionIndex = 0;
  int? selectedOptionIndex;
  Map<int, int> answers = {}; // Maps question index to selected answer index

  /// Save user's selected answer for current question
  void _selectOption(int optionIndex) {
    setState(() {
      selectedOptionIndex = optionIndex;
      answers[currentQuestionIndex] = optionIndex;
    });
  }

  /// Move to next question or submit quiz if on last question
  void _goToNextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = answers[currentQuestionIndex];
      });
    } else {
      _submitQuiz();
    }
  }

  /// Navigate back to previous question if not on first question
  void _goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedOptionIndex = answers[currentQuestionIndex];
      });
    }
  }

  /// Submit answers to API and get result
  Future<void> _submitQuiz() async {
    Navigator.pop(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );

    try {
      final result = await QuizService.submitQuizAnswers(
        widget.userId,
        List.generate(widget.questions.length, (i) => answers[i] ?? 0),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Call onComplete callback with result
      widget.onComplete(result);
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved indsendelse af quiz: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return AlertDialog(
        title: Text('No Questions'),
        content: Text('No quiz questions available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      );
    }

    final currentQuestion = widget.questions[currentQuestionIndex];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildTitle(),
              SizedBox(height: 10),
              _buildSubtitle(),
              SizedBox(height: 20),
              _buildProgressIndicator(),
              SizedBox(height: 20),
              _buildProgressBar(),
              SizedBox(height: 20),
              _buildQuestionText(currentQuestion.questionText),
              SizedBox(height: 15),
              _buildOptions(currentQuestion.options),
              SizedBox(height: 20),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          'WaveLength',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Tag quizzen!',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildSubtitle() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Besvar spørgsmålene og find ud af om i er på bølgelængde!',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${currentQuestionIndex + 1} af ${widget.questions.length}',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: (currentQuestionIndex + 1) / widget.questions.length,
        minHeight: 8,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      ),
    );
  }

  Widget _buildQuestionText(String questionText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      questionText,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build answer buttons with theme-aware colors and selection highlighting
  Widget _buildOptions(List<QuizOption> options) {
    return Column(
      children: List.generate(options.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _buildQuizOption(
            options[index].text,
            selectedOptionIndex == index,
            index,
          ),
        );
      }),
    );
  }

  Widget _buildQuizOption(String text, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectOption(index),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple[300] : Colors.purple[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: Colors.purple[800],
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build next/submit button with dynamic text based on progress
  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: selectedOptionIndex != null ? _goToNextQuestion : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        minimumSize: Size(double.infinity, 50),
        disabledBackgroundColor: Colors.grey,
      ),
      child: Text(
        currentQuestionIndex < widget.questions.length - 1 ? 'Næste' : 'Afslut',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
