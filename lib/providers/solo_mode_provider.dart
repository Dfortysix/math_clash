import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/question_generator.dart';
import '../services/google_play_games_service.dart';

class SoloModeState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final int score;
  final int timeRemaining;
  final bool isGameOver;
  final bool isLoading;
  final bool isSavingScore;
  final String? saveScoreError;

  SoloModeState({
    required this.questions,
    required this.currentQuestionIndex,
    required this.score,
    required this.timeRemaining,
    required this.isGameOver,
    required this.isLoading,
    required this.isSavingScore,
    this.saveScoreError,
  });

  SoloModeState copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    int? score,
    int? timeRemaining,
    bool? isGameOver,
    bool? isLoading,
    bool? isSavingScore,
    String? saveScoreError,
  }) {
    return SoloModeState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isGameOver: isGameOver ?? this.isGameOver,
      isLoading: isLoading ?? this.isLoading,
      isSavingScore: isSavingScore ?? this.isSavingScore,
      saveScoreError: saveScoreError ?? this.saveScoreError,
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
    isSavingScore: false,
  ));

  void startNewGame() {
    state = state.copyWith(
      questions: QuestionGenerator.generateRandomQuestions(),
      currentQuestionIndex: 0,
      score: 0,
      timeRemaining: 30,
      isGameOver: false,
      isLoading: false,
      saveScoreError: null,
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

    // Tự động lưu điểm khi game kết thúc
    if (isGameOver) {
      saveScore();
    }
  }

  void updateTimeRemaining(int timeRemaining) {
    state = state.copyWith(timeRemaining: timeRemaining);
  }

  Future<void> saveScore() async {
    if (state.score <= 0) return;

    state = state.copyWith(isSavingScore: true, saveScoreError: null);

    try {
      final success = await GooglePlayGamesService.saveScore(state.score, 'solo');
      
      if (success) {
        print('SoloModeProvider: Đã lưu điểm thành công');
      } else {
        state = state.copyWith(
          saveScoreError: 'Vui lòng đăng nhập bằng Google để lưu điểm',
        );
      }
    } catch (e) {
      state = state.copyWith(
        saveScoreError: 'Lỗi khi lưu điểm: $e',
      );
    } finally {
      state = state.copyWith(isSavingScore: false);
    }
  }

  void resetToInitialState() {
    state = SoloModeState(
      questions: [],
      currentQuestionIndex: 0,
      score: 0,
      timeRemaining: 30,
      isGameOver: false,
      isLoading: false,
      isSavingScore: false,
    );
  }

  void clearSaveScoreError() {
    state = state.copyWith(saveScoreError: null);
  }
}

final soloModeProvider = StateNotifierProvider<SoloModeNotifier, SoloModeState>((ref) {
  return SoloModeNotifier();
}); 