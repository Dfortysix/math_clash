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

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }
}

final pvpRoomProvider = StateNotifierProvider<PvPRoomNotifier, PvPRoomState>((ref) {
  return PvPRoomNotifier();
}); 