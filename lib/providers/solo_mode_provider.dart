import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/question_generator.dart';

class SoloModeState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final int score;
  final int timeRemaining;
  final bool isGameOver;
  final bool isLoading;

  SoloModeState({
    required this.questions,
    required this.currentQuestionIndex,
    required this.score,
    required this.timeRemaining,
    required this.isGameOver,
    required this.isLoading,
  });

  SoloModeState copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    int? score,
    int? timeRemaining,
    bool? isGameOver,
    bool? isLoading,
  }) {
    return SoloModeState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isGameOver: isGameOver ?? this.isGameOver,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SoloModeNotifier extends StateNotifier<SoloModeState> {
  SoloModeNotifier() : super(SoloModeState(
    questions: [],
    currentQuestionIndex: 0,
    score: 0,
    timeRemaining: 30,
    isGameOver: false,
    isLoading: false,
  ));

  void startNewGame() {
    state = state.copyWith(
      questions: QuestionGenerator.generateRandomQuestions(),
      currentQuestionIndex: 0,
      score: 0,
      timeRemaining: 30,
      isGameOver: false,
      isLoading: false,
    );
  }

  void answerQuestion(String selectedAnswer) {
    if (state.isGameOver || state.currentQuestionIndex >= state.questions.length) return;

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isCorrect = selectedAnswer == currentQuestion.correctAnswer;
    
    int newScore = state.score;
    if (isCorrect) {
      // Công thức tính điểm: base * độ khó * thời gian còn lại
      int baseScore = 10;
      int difficultyMultiplier = currentQuestion.difficulty;
      int timeBonus = (state.timeRemaining / 5).round(); // Thời gian còn lại chia 5
      newScore += baseScore * difficultyMultiplier * timeBonus;
    }

    int nextQuestionIndex = state.currentQuestionIndex + 1;
    bool isGameOver = nextQuestionIndex >= state.questions.length;

    state = state.copyWith(
      score: newScore,
      currentQuestionIndex: nextQuestionIndex,
      isGameOver: isGameOver,
    );
  }

  void updateTimeRemaining(int timeRemaining) {
    state = state.copyWith(timeRemaining: timeRemaining);
  }

  void resetToInitialState() {
    state = SoloModeState(
      questions: [],
      currentQuestionIndex: 0,
      score: 0,
      timeRemaining: 30,
      isGameOver: false,
      isLoading: false,
    );
  }
}

final soloModeProvider = StateNotifierProvider<SoloModeNotifier, SoloModeState>((ref) {
  return SoloModeNotifier();
}); 