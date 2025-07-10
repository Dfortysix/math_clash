import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GooglePlayGamesService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Đăng nhập bằng Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('GooglePlayGamesService: Bắt đầu đăng nhập Google...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('GooglePlayGamesService: Người dùng hủy đăng nhập Google');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      print('GooglePlayGamesService: Đăng nhập Google thành công - User ID: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi đăng nhập Google: $e');
      return null;
    }
  }

  // Đăng xuất Google
  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      print('GooglePlayGamesService: Đã đăng xuất Google');
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi đăng xuất Google: $e');
    }
  }

  // Lấy thông tin user hiện tại
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Kiểm tra xem user có đăng nhập Google không
  static bool isSignedInWithGoogle() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.providerData.any((profile) => profile.providerId == 'google.com');
  }

  // Lấy display name từ Google
  static String? getGoogleDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName;
  }

  // Lấy email từ Google
  static String? getGoogleEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  // Lấy profile picture từ Google
  static String? getGooglePhotoUrl() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.photoURL;
  }

  // Khởi tạo Google Play Games Services (tạm thời disabled)
  static Future<bool> initializeGamesServices() async {
    try {
      print('GooglePlayGamesService: Google Play Games Services tạm thời disabled');
      return false;
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi khởi tạo Google Play Games: $e');
      return false;
    }
  }

  // Đăng nhập Google Play Games (tạm thời disabled)
  static Future<bool> signInToGamesServices() async {
    try {
      print('GooglePlayGamesService: Google Play Games Services tạm thời disabled');
      return false;
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi đăng nhập Google Play Games: $e');
      return false;
    }
  }

  // Đăng xuất Google Play Games (tạm thời disabled)
  static Future<void> signOutFromGamesServices() async {
    try {
      print('GooglePlayGamesService: Google Play Games Services tạm thời disabled');
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi đăng xuất Google Play Games: $e');
    }
  }

  // Lưu điểm lên Google Play Games Leaderboard (tạm thời disabled)
  static Future<bool> submitScoreToLeaderboard(int score, String leaderboardId) async {
    try {
      print('GooglePlayGamesService: Google Play Games Services tạm thời disabled');
      return false;
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi lưu điểm lên Google Play Games: $e');
      return false;
    }
  }

  // Hiển thị Google Play Games Leaderboard (tạm thời disabled)
  static Future<void> showLeaderboard(String leaderboardId) async {
    try {
      print('GooglePlayGamesService: Google Play Games Services tạm thời disabled');
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi hiển thị leaderboard: $e');
    }
  }

  // Hiển thị tất cả Google Play Games Leaderboards (tạm thời disabled)
  static Future<void> showAllLeaderboards() async {
    try {
      print('GooglePlayGamesService: Google Play Games Services tạm thời disabled');
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi hiển thị leaderboards: $e');
    }
  }

  // Lấy điểm cao nhất từ Google Play Games (tạm thời disabled)
  static Future<int?> getHighScore(String leaderboardId) async {
    try {
      print('GooglePlayGamesService: Google Play Games Services tạm thời disabled');
      return null;
    } catch (e) {
      print('GooglePlayGamesService: Lỗi khi lấy điểm cao nhất: $e');
      return null;
    }
  }
} 