import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvp_room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/pvp_room.dart';
import '../../l10n/app_localizations.dart';

class PvPRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const PvPRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<PvPRoomScreen> createState() => _PvPRoomScreenState();
}

class _PvPRoomScreenState extends ConsumerState<PvPRoomScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lắng nghe phòng khi vào màn hình
    ref.read(pvpRoomProvider.notifier).listenRoom(widget.roomId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _leaveRoomOnAppExit();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _leaveRoomOnAppExit() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(pvpRoomProvider.notifier).leaveRoomSilently(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pvpRoomState = ref.watch(pvpRoomProvider);
    final room = pvpRoomState.room;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    if (room == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isHost = room.players.isNotEmpty && room.players.first.userId == currentUser?.uid;
    final canStartGame = room.players.length >= 2 && isHost && room.status == 'waiting';
    final isCurrentUserReady = room.players.any((p) => p.userId == currentUser?.uid && p.ready);
    final canShowReadyButton = currentUser != null && !isHost;
    final canShowStartButton = room.players.length == 2 && isHost && room.players.every((p) => p.ready);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pvpMode),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Ẩn nút back
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _showLeaveRoomDialog(context),
            tooltip: AppLocalizations.of(context)!.leaveRoom,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA),
              Color(0xFFB2EBF2),
              Color(0xFF80DEEA),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Thông tin phòng
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.roomCode}: ${room.roomId}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            _buildStatusChip(room.status),
                            const SizedBox(height: 8),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.blue),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: room.roomId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.roomCodeCopied),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: AppLocalizations.of(context)!.copyRoomCode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)!.players}: ${room.players.length}/2',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Danh sách người chơi
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.playersInRoom,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200, // Giới hạn chiều cao
                          child: ListView.builder(
                            itemCount: room.players.length,
                            itemBuilder: (context, index) {
                              final player = room.players[index];
                              final isCurrentUser = player.userId == currentUser?.uid;
                              return Card(
                                color: isCurrentUser ? Colors.blue.shade50 : null,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: player.avatarUrl.isNotEmpty
                                        ? NetworkImage(player.avatarUrl)
                                        : null,
                                    child: player.avatarUrl.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          player.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (index == 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)!.roomHost,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (isHost && !isCurrentUser) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          tooltip: AppLocalizations.of(context)!.kick,
                                          onPressed: () async {
                                            await ref.read(pvpRoomProvider.notifier).kickPlayer(player.userId);
                                          },
                                        ),
                                      ],
                                      if (isCurrentUser) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)!.you,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text('${AppLocalizations.of(context)!.score}: ${player.score}'),
                                      const SizedBox(width: 12),
                                      player.ready
                                        ? Row(children: [
                                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                            const SizedBox(width: 4),
                                            Text(AppLocalizations.of(context)!.ready, style: const TextStyle(color: Colors.green)),
                                          ])
                                        : Row(children: [
                                            const Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
                                            const SizedBox(width: 4),
                                            Text(AppLocalizations.of(context)!.notReady, style: const TextStyle(color: Colors.orange)),
                                          ]),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (canShowReadyButton)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(isCurrentUserReady ? Icons.close : Icons.check),
                              label: Text(isCurrentUserReady ? AppLocalizations.of(context)!.cancelReady : AppLocalizations.of(context)!.ready),
                              onPressed: () async {
                                await ref.read(pvpRoomProvider.notifier).setReady(currentUser!.uid, !isCurrentUserReady);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrentUserReady ? Colors.orange : Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Nút bắt đầu game
                if (canShowStartButton) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(AppLocalizations.of(context)!.startGame, style: const TextStyle(fontSize: 18)),
                      onPressed: () {
                        // TODO: Chuyển sang màn hình chơi PvP
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.featureInDevelopment)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ] else if (room.players.length < 2) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Text(AppLocalizations.of(context)!.waitingForPlayers),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'waiting':
        color = Colors.orange;
        text = AppLocalizations.of(context)!.waiting;
        icon = Icons.schedule;
        break;
      case 'playing':
        color = Colors.green;
        text = AppLocalizations.of(context)!.playing;
        icon = Icons.play_arrow;
        break;
      case 'finished':
        color = Colors.grey;
        text = AppLocalizations.of(context)!.finished;
        icon = Icons.stop;
        break;
      default:
        color = Colors.grey;
        text = AppLocalizations.of(context)!.unknown;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.leaveRoom),
        content: Text(AppLocalizations.of(context)!.leaveRoomConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Hiển thị loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Text(AppLocalizations.of(context)!.leavingRoom),
                    ],
                  ),
                ),
              );
              try {
                final authState = ref.read(authProvider);
                final user = authState.user;
                if (user != null) {
                  final success = await ref.read(pvpRoomProvider.notifier).leaveRoom(user.uid);
                  // Đóng loading dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                  if (success && mounted) {
                    // Điều hướng về màn hình chính
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  } else if (mounted) {
                    // Hiển thị lỗi nếu có
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.leaveRoomError),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                // Đóng loading dialog nếu có lỗi
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppLocalizations.of(context)!.error}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.leaveRoom),
          ),
        ],
      ),
    );
  }
} 