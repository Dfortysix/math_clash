import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      print('FirebaseService: Bắt đầu khởi tạo Firebase...');
      await Firebase.initializeApp();
      print('FirebaseService: Firebase đã được khởi tạo thành công');
      
      // Kiểm tra trạng thái auth
      final currentUser = _auth.currentUser;
      print('FirebaseService: Trạng thái auth sau khởi tạo - User: ${currentUser?.uid}');
    } catch (e) {
      print('FirebaseService: Lỗi khi khởi tạo Firebase: $e');
      rethrow;
    }
  }

  // Authentication methods
  static Future<UserCredential?> signInAnonymously() async {
    try {
      print('FirebaseService: Bắt đầu đăng nhập ẩn danh...');
      final userCredential = await _auth.signInAnonymously();
      print('FirebaseService: Đăng nhập ẩn danh thành công - User ID: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('FirebaseService: Lỗi khi đăng nhập ẩn danh: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    final user = _auth.currentUser;
    print('FirebaseService: getCurrentUser - User: ${user?.uid}');
    return user;
  }

  static Future<User?> ensureUserSignedIn() async {
    try {
      User? currentUser = _auth.currentUser;
      print('FirebaseService: ensureUserSignedIn - Current user: ${currentUser?.uid}');
      
      if (currentUser == null) {
        print('FirebaseService: Không có user, đang đăng nhập ẩn danh...');
        final userCredential = await signInAnonymously();
        currentUser = userCredential?.user;
        print('FirebaseService: Sau khi đăng nhập - User: ${currentUser?.uid}');
      }
      
      return currentUser;
    } catch (e) {
      print('FirebaseService: Lỗi trong ensureUserSignedIn: $e');
      return null;
    }
  }

  static Future<bool> checkFirebaseConfiguration() async {
    try {
      print('FirebaseService: Kiểm tra cấu hình Firebase...');
      
      // Kiểm tra xem Firebase có được khởi tạo không
      final apps = Firebase.apps;
      print('FirebaseService: Số lượng Firebase apps: ${apps.length}');
      
      // Kiểm tra xem có thể truy cập Firestore không
      await _firestore.collection('test').limit(1).get();
      print('FirebaseService: Có thể truy cập Firestore');
      
      return true;
    } catch (e) {
      print('FirebaseService: Lỗi cấu hình Firebase: $e');
      return false;
    }
  }

  // Firestore methods for leaderboard
  static Future<void> saveScore(String userId, String username, int score, String gameMode) async {
    try {
      print('FirebaseService: Bắt đầu lưu điểm - userId: $userId, username: $username, score: $score, gameMode: $gameMode');
      
      final docRef = await _firestore.collection('leaderboard').add({
        'userId': userId,
        'username': username,
        'score': score,
        'gameMode': gameMode,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('FirebaseService: Đã lưu điểm thành công với document ID: ${docRef.id}');
    } catch (e) {
      print('FirebaseService: Lỗi khi lưu điểm: $e');
      rethrow; // Ném lại lỗi để xử lý ở tầng trên
    }
  }

  // Phương thức lưu điểm không cần authentication (chỉ để test)
  static Future<void> saveScoreWithoutAuth(String username, int score, String gameMode) async {
    try {
      print('FirebaseService: Bắt đầu lưu điểm không auth - username: $username, score: $score, gameMode: $gameMode');
      
      final docRef = await _firestore.collection('leaderboard').add({
        'userId': 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        'username': username,
        'score': score,
        'gameMode': gameMode,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('FirebaseService: Đã lưu điểm thành công với document ID: ${docRef.id}');
    } catch (e) {
      print('FirebaseService: Lỗi khi lưu điểm không auth: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTopScores(String gameMode, {int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('leaderboard')
          .where('gameMode', isEqualTo: gameMode)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting top scores: $e');
      return [];
    }
  }

  static Future<int> getUserRank(String userId, String gameMode) async {
    try {
      final userScore = await _firestore
          .collection('leaderboard')
          .where('userId', isEqualTo: userId)
          .where('gameMode', isEqualTo: gameMode)
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      if (userScore.docs.isEmpty) return -1;

      final userScoreValue = userScore.docs.first.data()['score'];

      final higherScores = await _firestore
          .collection('leaderboard')
          .where('gameMode', isEqualTo: gameMode)
          .where('score', isGreaterThan: userScoreValue)
          .get();

      return higherScores.docs.length + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return -1;
    }
  }
}
