import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String id;
  final String userId;
  final String username;
  final int score;
  final DateTime timestamp;
  final String gameMode;

  LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.score,
    required this.timestamp,
    required this.gameMode,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, String id) {
    return LeaderboardEntry(
      id: id,
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Anonymous',
      score: map['score'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gameMode: map['gameMode'] ?? 'solo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'score': score,
      'timestamp': timestamp,
      'gameMode': gameMode,
    };
  }

  @override
  String toString() {
    return 'LeaderboardEntry(id: $id, userId: $userId, username: $username, score: $score, gameMode: $gameMode)';
  }
} 