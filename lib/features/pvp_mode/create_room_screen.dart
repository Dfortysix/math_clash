import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvp_room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/question_generator.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  String? _roomId;

  @override
  void initState() {
    super.initState();
    _createRoom();
  }

  Future<void> _createRoom() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    print('[PvP] User: $user');
    if (user == null) {
      print('[PvP] Không có user, cần đăng nhập Google!');
      return;
    }
    final questions = QuestionGenerator.generateRandomQuestions().map((q) => q.toMap()).toList();
    print('[PvP] Questions: $questions');
    try {
      final roomId = await ref.read(pvpRoomProvider.notifier).createRoom(
        userId: user.uid,
        displayName: user.displayName ?? 'Unknown',
        avatarUrl: user.photoURL ?? '',
        questions: questions,
      );
      print('[PvP] RoomId: $roomId');
      setState(() {
        _roomId = roomId;
      });
    } catch (e, stack) {
      print('[PvP] Lỗi khi tạo phòng: $e');
      print(stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pvpRoomState = ref.watch(pvpRoomProvider);
    final room = pvpRoomState.room;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo phòng PvP'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: room == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Chia sẻ mã phòng cho bạn bè',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    room.roomId,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 32),
                  const Text('Đang chờ đối thủ vào phòng...', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: room.players.map((player) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: player.avatarUrl.isNotEmpty ? NetworkImage(player.avatarUrl) : null,
                            radius: 32,
                            child: player.avatarUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
                          ),
                          const SizedBox(height: 8),
                          Text(player.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  if (room.players.length < 2)
                    const CircularProgressIndicator()
                  else
                    const Text('Đã đủ người, chuẩn bị bắt đầu!', style: TextStyle(color: Colors.green, fontSize: 18)),
                ],
              ),
            ),
    );
  }
} 