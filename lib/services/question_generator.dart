import '../models/question.dart';
import 'dart:math';

class QuestionGenerator {
  static final _random = Random();

  static List<Question> generateRandomQuestions({int count = 15}) {
    List<Question> questions = [];
    for (int i = 0; i < count; i++) {
      questions.add(_generateQuestion(i));
    }
    return questions;
  }

  static Question _generateQuestion(int index) {
    // Thêm các phép toán mới
    final operations = ['+', '-', '×', '÷', '^', '√', 'log'];
    final op = operations[_random.nextInt(operations.length)];
    int a = _random.nextInt(20) + 1;
    int b = _random.nextInt(10) + 1;
    int difficulty = 1 + _random.nextInt(3); // 1-3
    String content;
    int answer;
    switch (op) {
      case '+':
        answer = a + b;
        content = '$a + $b = ?';
        break;
      case '-':
        answer = a - b;
        content = '$a - $b = ?';
        break;
      case '×':
        answer = a * b;
        content = '$a × $b = ?';
        break;
      case '÷':
        answer = a * b; // Đảm bảo chia hết
        content = '${a * b} ÷ $a = ?';
        answer = b;
        break;
      case '^':
        answer = pow(a % 6 + 2, b % 2 + 2).toInt(); // Giới hạn số nhỏ
        content = '${a % 6 + 2} ^ ${b % 2 + 2} = ?';
        break;
      case '√':
        int n = (a % 10 + 2);
        answer = n;
        content = '√${n * n} = ?';
        break;
      case 'log':
        int base = 2 + _random.nextInt(3); // 2, 3, 4
        int exp = 1 + _random.nextInt(3); // 1-3
        answer = exp;
        int value = pow(base, exp).toInt();
        content = 'log$base($value) = ?';
        break;
      default:
        answer = 0;
        content = '';
    }
    // Sinh các lựa chọn ngẫu nhiên
    Set<String> options = {answer.toString()};
    while (options.length < 4) {
      int fake = answer + _random.nextInt(11) - 5;
      if (fake != answer && fake >= 0) options.add(fake.toString());
    }
    List<String> optionsList = options.toList()..shuffle();
    return Question(
      id: 'q_$index',
      content: content,
      options: optionsList,
      correctAnswer: answer.toString(),
      difficulty: difficulty,
    );
  }
}
