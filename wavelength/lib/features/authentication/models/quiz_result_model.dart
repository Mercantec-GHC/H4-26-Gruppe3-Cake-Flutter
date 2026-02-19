/// Quiz result with match percentage and pass status
class QuizResult {
  final int matchPercent;
  final bool passed;

  QuizResult({
    required this.matchPercent,
    required this.passed,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      matchPercent: json['matchPercent'] ?? 0,
      passed: json['passed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchPercent': matchPercent,
      'passed': passed,
    };
  }
}
