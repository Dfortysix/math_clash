import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvp_room_provider.dart';
import '../../providers/auth_provider.dart';
import 'pvp_room_screen.dart';
import '../../l10n/app_localizations.dart';

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
        _errorText = AppLocalizations.of(context)!.pleaseEnterRoomCode;
        _isJoining = false;
      });
      return;
    }
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) {
      setState(() {
        _errorText = AppLocalizations.of(context)!.needGoogleSignIn;
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
        _errorText = ref.read(pvpRoomProvider).error ?? AppLocalizations.of(context)!.cannotJoinRoom;
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pvpRoomState = ref.watch(pvpRoomProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.joinPvpRoom),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          if (pvpRoomState.room != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _showLeaveRoomDialog(context),
              tooltip: AppLocalizations.of(context)!.leaveRoom,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.enterRoomCode,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _roomIdController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.roomCode,
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
                                    : Text(
                    AppLocalizations.of(context)!.join,
                    style: const TextStyle(fontSize: 20),
                  ),
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
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text(AppLocalizations.of(context)!.leaveRoom),
          ),
        ],
      ),
    );
  }
} 