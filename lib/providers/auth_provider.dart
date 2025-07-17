import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_play_games_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isGoogleSignedIn;

  AuthState({
    this.user,
    required this.isLoading,
    this.error,
    required this.isGoogleSignedIn,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isGoogleSignedIn,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isGoogleSignedIn: isGoogleSignedIn ?? this.isGoogleSignedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(
    isLoading: false,
    isGoogleSignedIn: false,
  )) {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Lắng nghe thay đổi trạng thái authentication
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final isGoogleSignedIn = GooglePlayGamesService.isSignedInWithGoogle();
      state = state.copyWith(
        user: user,
        isGoogleSignedIn: isGoogleSignedIn,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final userCredential = await GooglePlayGamesService.signInWithGoogle();
      
      if (userCredential != null) {
        state = state.copyWith(
          user: userCredential.user,
          isGoogleSignedIn: true,
          isLoading: false,
        );
        print('AuthProvider: Đăng nhập Google thành công');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Đăng nhập Google thất bại',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
                  error: 'Error signing in with Google: $e',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await GooglePlayGamesService.signOutGoogle();
      
      state = state.copyWith(
        user: null,
        isGoogleSignedIn: false,
        isLoading: false,
      );
      
      print('AuthProvider: Đăng xuất thành công');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
                  error: 'Error signing out: $e',
      );
    }
  }

  String? getDisplayName() {
    return GooglePlayGamesService.getGoogleDisplayName();
  }

  String? getEmail() {
    return GooglePlayGamesService.getGoogleEmail();
  }

  String? getPhotoUrl() {
    return GooglePlayGamesService.getGooglePhotoUrl();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
}); 