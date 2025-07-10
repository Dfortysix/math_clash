import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';
import '../services/firebase_service.dart';

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;
  final String selectedGameMode;
  final bool isGoogleSignedIn;

  LeaderboardState({
    required this.entries,
    required this.isLoading,
    this.error,
    required this.selectedGameMode,
    required this.isGoogleSignedIn,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
    String? selectedGameMode,
    bool? isGoogleSignedIn,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedGameMode: selectedGameMode ?? this.selectedGameMode,
      isGoogleSignedIn: isGoogleSignedIn ?? this.isGoogleSignedIn,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier() : super(LeaderboardState(
    entries: [],
    isLoading: false,
    selectedGameMode: 'solo',
    isGoogleSignedIn: false,
  )) {
    _checkGoogleSignInStatus();
  }

  void _checkGoogleSignInStatus() {
    final isGoogleSignedIn = FirebaseService.isSignedInWithGoogle();
    state = state.copyWith(isGoogleSignedIn: isGoogleSignedIn);
  }

  Future<void> loadLeaderboard({String? gameMode}) async {
    final mode = gameMode ?? state.selectedGameMode;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await FirebaseService.getTopScores(mode, limit: 50);
      final entries = data.map((map) => 
        LeaderboardEntry.fromMap(map, map['id'] ?? '')
      ).toList();

      state = state.copyWith(
        entries: entries,
        isLoading: false,
        selectedGameMode: mode,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> saveScore(int score, String gameMode) async {
    print('LeaderboardProvider: Bắt đầu saveScore - score: $score, gameMode: $gameMode');
    
    // Kiểm tra xem user có đăng nhập Google không
    if (!FirebaseService.isSignedInWithGoogle()) {
      print('LeaderboardProvider: User chưa đăng nhập Google');
      state = state.copyWith(
        error: 'Vui lòng đăng nhập bằng Google để lưu điểm',
      );
      return false;
    }
    
    try {
      await FirebaseService.saveScoreForGoogleUser(score, gameMode);
      print('LeaderboardProvider: Đã lưu điểm thành công, đang reload leaderboard');
      await loadLeaderboard(gameMode: gameMode);
      print('LeaderboardProvider: Đã reload leaderboard xong');
      return true;
    } catch (e) {
      print('LeaderboardProvider: Lỗi khi lưu điểm: $e');
      state = state.copyWith(
        error: 'Lỗi khi lưu điểm: $e',
      );
      return false;
    }
  }

  Future<int> getUserRank(String gameMode) async {
    final user = FirebaseService.getCurrentUser();
    if (user != null) {
      return await FirebaseService.getUserRank(user.uid, gameMode);
    }
    return -1;
  }

  Future<int?> getUserHighScore(String gameMode) async {
    return await FirebaseService.getUserHighScore(gameMode);
  }

  void changeGameMode(String gameMode) {
    loadLeaderboard(gameMode: gameMode);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateGoogleSignInStatus() {
    _checkGoogleSignInStatus();
  }
}

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier();
}); 