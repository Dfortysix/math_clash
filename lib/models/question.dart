class Question {
  final String id;
  final String content;
  final List<String> options;
  final String correctAnswer;
  final int difficulty; // 1: dễ, 2: vừa, 3: khó

  Question({
    required this.id,
    required this.content,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'options': options,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
    };
  }
} 