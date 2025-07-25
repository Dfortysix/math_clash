import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvp_room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/question_generator.dart';
import 'pvp_room_screen.dart'; // Added import for PvPRoomScreen
import '../../l10n/app_localizations.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  String? _roomId;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _createRoom());
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
    print('[PvP] Build CreateRoomScreen');
    final pvpRoomState = ref.watch(pvpRoomProvider);
    final room = pvpRoomState.room;
    
    // Nếu đã có phòng, chuyển sang màn hình phòng (chỉ 1 lần)
    if (room != null && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => PvPRoomScreen(roomId: room.roomId)),
        );
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createPvpRoom),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.creatingRoom),
          ],
        ),
      ),
    );
  }

  void _showLeaveRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.leaveRoom),
        content: Text(AppLocalizations.of(context)!.leaveRoomConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authState = ref.read(authProvider);
              final user = authState.user;
              if (user != null) {
                await ref.read(pvpRoomProvider.notifier).leaveRoom(user.uid);
                Navigator.of(context).pop(); // Quay về màn hình chính
              }
            },
            child: Text(AppLocalizations.of(context)!.leaveRoom),
          ),
        ],
      ),
    );
  }
} 