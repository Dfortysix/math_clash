import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvp_room_provider.dart';
import '../../providers/auth_provider.dart';
import 'pvp_room_screen.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  String? _errorText;
  bool _isJoining = false;

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    setState(() {
      _isJoining = true;
      _errorText = null;
    });
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập mã phòng';
        _isJoining = false;
      });
      return;
    }
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) {
      setState(() {
        _errorText = 'Bạn cần đăng nhập Google';
        _isJoining = false;
      });
      return;
    }
    final result = await ref.read(pvpRoomProvider.notifier).joinRoom(
      roomId: roomId,
      userId: user.uid,
      displayName: user.displayName ?? 'Unknown',
      avatarUrl: user.photoURL ?? '',
    );
    if (result != null) {
      // Thành công, chuyển sang màn hình phòng
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PvPRoomScreen(roomId: result)),
      );
    } else {
      setState(() {
        _errorText = ref.read(pvpRoomProvider).error ?? 'Không thể tham gia phòng';
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pvpRoomState = ref.watch(pvpRoomProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tham gia phòng PvP'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          if (pvpRoomState.room != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _showLeaveRoomDialog(context),
              tooltip: 'Rời phòng',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Nhập mã phòng để tham gia',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _roomIdController,
              decoration: InputDecoration(
                labelText: 'Mã phòng',
                border: OutlineInputBorder(),
                errorText: _errorText,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, letterSpacing: 2),
              enabled: !_isJoining,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Tham gia phòng', style: TextStyle(fontSize: 20)),
                onPressed: _isJoining ? null : _joinRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời phòng'),
        content: const Text('Bạn có chắc muốn rời phòng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
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
            child: const Text('Rời phòng'),
          ),
        ],
      ),
    );
  }
} 