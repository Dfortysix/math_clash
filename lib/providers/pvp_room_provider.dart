import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pvp_room.dart';
import '../services/firebase_service.dart';

class PvPRoomState {
  final PvPRoom? room;
  final bool isLoading;
  final String? error;

  PvPRoomState({
    this.room,
    this.isLoading = false,
    this.error,
  });

  PvPRoomState copyWith({
    PvPRoom? room,
    bool? isLoading,
    String? error,
  }) {
    return PvPRoomState(
      room: room ?? this.room,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PvPRoomNotifier extends StateNotifier<PvPRoomState> {
  StreamSubscription<DocumentSnapshot>? _roomSub;

  PvPRoomNotifier() : super(PvPRoomState());

  Future<String?> createRoom({
    required String userId,
    required String displayName,
    required String avatarUrl,
    required List<Map<String, dynamic>> questions,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final roomId = await FirebaseService.createPvPRoom(
        userId: userId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        questions: questions,
        // Truyền các trường mới nếu cần
      );
      listenRoom(roomId);
      return roomId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void listenRoom(String roomId) {
    _roomSub?.cancel();
    _roomSub = FirebaseFirestore.instance
        .collection('pvp_rooms')
        .doc(roomId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        state = state.copyWith(
          room: PvPRoom.fromMap(doc.data()!, doc.id),
          isLoading: false,
        );
      }
    }, onError: (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    });
  }

  Future<String?> joinRoom({
    required String roomId,
    required String userId,
    required String displayName,
    required String avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final docRef = FirebaseFirestore.instance.collection('pvp_rooms').doc(roomId);
      final doc = await docRef.get();
      if (!doc.exists) {
        state = state.copyWith(isLoading: false, error: 'Room does not exist!');
        return null;
      }
      final data = doc.data()!;
      final players = (data['players'] as List<dynamic>? ?? []);
      if (players.length >= 2) {
        state = state.copyWith(isLoading: false, error: 'Room is full!');
        return null;
      }
      // Kiểm tra nếu user đã có trong phòng
      final alreadyInRoom = players.any((p) => p['userId'] == userId);
      if (alreadyInRoom) {
        listenRoom(roomId);
        return roomId;
      }
      // Thêm user vào danh sách players
      players.add(PlayerInRoom(
        userId: userId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        score: 0,
        ready: false,
        currentQuestion: 0,
        answers: <String>[],
        isFinished: false,
      ).toMap());
      await docRef.update({
        'players': players,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      listenRoom(roomId);
      return roomId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  // Rời phòng
  Future<bool> leaveRoom(String userId) async {
    if (state.room == null) return false;
    
    try {
      final success = await FirebaseService.leaveRoom(state.room!.roomId, userId);
      if (success) {
        _roomSub?.cancel();
        state = PvPRoomState(); // Reset state
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Rời phòng im lặng (không cập nhật UI, không context, dùng cho lifecycle)
  Future<void> leaveRoomSilently(String userId) async {
    if (state.room == null) return;
    try {
      await FirebaseService.leaveRoom(state.room!.roomId, userId);
      _roomSub?.cancel();
      state = PvPRoomState(); // Reset state
    } catch (e) {
      // Không cập nhật state.error, chỉ log nếu cần
    }
  }

  // Đánh dấu sẵn sàng hoặc hủy sẵn sàng cho user hiện tại
  Future<void> setReady(String userId, bool ready) async {
    if (state.room == null) return;
    final roomId = state.room!.roomId;
    final players = List<PlayerInRoom>.from(state.room!.players);
    final index = players.indexWhere((p) => p.userId == userId);
    if (index == -1) return;
    final old = players[index];
    players[index] = PlayerInRoom(
      userId: old.userId,
      displayName: old.displayName,
      avatarUrl: old.avatarUrl,
      score: old.score,
      ready: ready,
      currentQuestion: old.currentQuestion,
      answers: old.answers,
      isFinished: old.isFinished,
    );
    // Cập nhật lên Firestore
    await FirebaseFirestore.instance.collection('pvp_rooms').doc(roomId).update({
      'players': players.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Chủ phòng kick người chơi khác khỏi phòng
  Future<void> kickPlayer(String userId) async {
    if (state.room == null) return;
    final roomId = state.room!.roomId;
    final players = List<PlayerInRoom>.from(state.room!.players);
    final index = players.indexWhere((p) => p.userId == userId);
    if (index == -1) return;
    players.removeAt(index);
    await FirebaseFirestore.instance.collection('pvp_rooms').doc(roomId).update({
      'players': players.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Chủ phòng bắt đầu game
  Future<void> startGame() async {
    if (state.room == null) return;
    final roomId = state.room!.roomId;
    await FirebaseFirestore.instance.collection('pvp_rooms').doc(roomId).update({
      'status': 'playing',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Trả lời câu hỏi PvP
  Future<void> answerQuestionPvp({
    required String userId,
    required String answer,
    required int scoreDelta,
    required bool isLastQuestion,
  }) async {
    if (state.room == null) return;
    final roomId = state.room!.roomId;
    final players = List<PlayerInRoom>.from(state.room!.players);
    final index = players.indexWhere((p) => p.userId == userId);
    if (index == -1) return;
    final player = players[index];
    final newAnswers = List<String>.from(player.answers)..add(answer);
    players[index] = PlayerInRoom(
      userId: player.userId,
      displayName: player.displayName,
      avatarUrl: player.avatarUrl,
      score: player.score + scoreDelta,
      ready: player.ready,
      currentQuestion: player.currentQuestion + 1,
      answers: newAnswers,
      isFinished: isLastQuestion,
    );
    await FirebaseFirestore.instance.collection('pvp_rooms').doc(roomId).update({
      'players': players.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cập nhật trạng thái phòng
  Future<void> updateRoomStatus(String roomId, String status) async {
    await FirebaseFirestore.instance.collection('pvp_rooms').doc(roomId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }
}

final pvpRoomProvider = StateNotifierProvider<PvPRoomNotifier, PvPRoomState>((ref) {
  return PvPRoomNotifier();
}); 