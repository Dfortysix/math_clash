import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvp_room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/pvp_room.dart';

class PvPRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const PvPRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<PvPRoomScreen> createState() => _PvPRoomScreenState();
}

class _PvPRoomScreenState extends ConsumerState<PvPRoomScreen> {
  @override
  void initState() {
    super.initState();
    // Lắng nghe phòng khi vào màn hình
    ref.read(pvpRoomProvider.notifier).listenRoom(widget.roomId);
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Phòng ${room.roomId}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _showLeaveRoomDialog(context),
            tooltip: 'Rời phòng',
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
                          'Mã phòng: ${room.roomId}',
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
                                  const SnackBar(
                                    content: Text('Đã sao chép mã phòng!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Sao chép mã phòng',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Người chơi: ${room.players.length}/2',
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
                        const Text(
                          'Người chơi trong phòng:',
                          style: TextStyle(
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
                                          child: const Text(
                                            'Chủ phòng',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                                          child: const Text(
                                            'Bạn',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text('Điểm: ${player.score}'),
                                  trailing: player.ready
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : const Icon(Icons.schedule, color: Colors.orange),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Nút bắt đầu game
                if (canStartGame) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Bắt đầu game', style: TextStyle(fontSize: 18)),
                      onPressed: () {
                        // TODO: Chuyển sang màn hình chơi PvP
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chức năng đang phát triển!')),
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
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Đang chờ người chơi khác...'),
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
        text = 'Chờ người chơi';
        icon = Icons.schedule;
        break;
      case 'playing':
        color = Colors.green;
        text = 'Đang chơi';
        icon = Icons.play_arrow;
        break;
      case 'finished':
        color = Colors.grey;
        text = 'Đã kết thúc';
        icon = Icons.stop;
        break;
      default:
        color = Colors.grey;
        text = 'Không xác định';
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