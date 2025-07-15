import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerInRoom {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final int score;
  final bool ready;

  PlayerInRoom({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.score,
    required this.ready,
  });

  factory PlayerInRoom.fromMap(Map<String, dynamic> map) {
    return PlayerInRoom(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      score: map['score'] ?? 0,
      ready: map['ready'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'score': score,
      'ready': ready,
    };
  }
}

class PvPRoom {
  final String roomId;
  final String status; // waiting, playing, finished
  final List<PlayerInRoom> players;
  final List<Map<String, dynamic>> questions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? winnerId;

  PvPRoom({
    required this.roomId,
    required this.status,
    required this.players,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
    this.winnerId,
  });

  factory PvPRoom.fromMap(Map<String, dynamic> map, String id) {
    return PvPRoom(
      roomId: id,
      status: map['status'] ?? 'waiting',
      players: (map['players'] as List<dynamic>? ?? [])
          .map((e) => PlayerInRoom.fromMap(e as Map<String, dynamic>))
          .toList(),
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      winnerId: map['winnerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'players': players.map((e) => e.toMap()).toList(),
      'questions': questions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (winnerId != null) 'winnerId': winnerId,
    };
  }
} 