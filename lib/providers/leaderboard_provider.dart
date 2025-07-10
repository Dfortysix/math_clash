import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';
import '../services/firebase_service.dart';

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;
  final String selectedGameMode;

  LeaderboardState({
    required this.entries,
    required this.isLoading,
    this.error,
    required this.selectedGameMode,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
    String? selectedGameMode,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedGameMode: selectedGameMode ?? this.selectedGameMode,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier() : super(LeaderboardState(
    entries: [],
    isLoading: false,
    selectedGameMode: 'solo',
  ));

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

  Future<void> saveScore(String username, int score, String gameMode) async {
    print('LeaderboardProvider: Bắt đầu saveScore - username: $username, score: $score, gameMode: $gameMode');
    
    try {
      // Thử lưu điểm không cần authentication trước
      print('LeaderboardProvider: Thử lưu điểm không cần auth...');
      await FirebaseService.saveScoreWithoutAuth(username, score, gameMode);
      print('LeaderboardProvider: Đã lưu điểm thành công, đang reload leaderboard');
      await loadLeaderboard(gameMode: gameMode);
      print('LeaderboardProvider: Đã reload leaderboard xong');
    } catch (e) {
      print('LeaderboardProvider: Lỗi khi lưu điểm không auth, thử với auth...');
      
      // Nếu không được, thử với authentication
      try {
        final user = await FirebaseService.ensureUserSignedIn();
        print('LeaderboardProvider: User sau khi đảm bảo đăng nhập: ${user?.uid}');
        
        if (user != null) {
          await FirebaseService.saveScore(user.uid, username, score, gameMode);
          print('LeaderboardProvider: Đã lưu điểm thành công với auth, đang reload leaderboard');
          await loadLeaderboard(gameMode: gameMode);
          print('LeaderboardProvider: Đã reload leaderboard xong');
        } else {
          print('LeaderboardProvider: Không thể đăng nhập user');
          throw Exception('Không thể đăng nhập user');
        }
      } catch (authError) {
        print('LeaderboardProvider: Lỗi khi lưu điểm với auth: $authError');
        rethrow;
      }
    }
  }

  Future<int> getUserRank(String gameMode) async {
    final user = FirebaseService.getCurrentUser();
    if (user != null) {
      return await FirebaseService.getUserRank(user.uid, gameMode);
    }
    return -1;
  }

  void changeGameMode(String gameMode) {
    loadLeaderboard(gameMode: gameMode);
  }
}

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier();
}); 