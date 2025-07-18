import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvp_room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'pvp_room_screen.dart';

class PvPGameScreen extends ConsumerStatefulWidget {
  final String roomId;
  const PvPGameScreen({super.key, required this.roomId});

  @override
  ConsumerState<PvPGameScreen> createState() => _PvPGameScreenState();
}

class _PvPGameScreenState extends ConsumerState<PvPGameScreen> {
  int _time = 15;
  late PageController _pageController;
  bool _isAnswered = false;
  String? _selectedAnswer;
  late final String _userId;
  late final String _opponentId;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final user = ref.read(authProvider).user;
    _userId = user?.uid ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(pvpRoomProvider).room;
    if (room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final players = room.players;
    final me = players.firstWhere((p) => p.userId == _userId);
    final opponent = players.firstWhere((p) => p.userId != _userId, orElse: () => me);
    final questions = room.questions;
    final currentIndex = me.currentQuestion;
    final isFinished = me.isFinished;
    final myScore = me.score;
    final opponentScore = opponent.score;
    final currentQuestion = currentIndex < questions.length ? questions[currentIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pvpMode),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPlayerInfo(context, me, isMe: true),
                _buildPlayerInfo(context, opponent, isMe: false),
              ],
            ),
            const SizedBox(height: 16),
            if (isFinished || currentQuestion == null)
              _buildFinishScreen(context, myScore, opponentScore)
            else
              _buildQuestion(context, currentQuestion, currentIndex, questions.length, me, room),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context, player, {required bool isMe}) {
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: player.avatarUrl.isNotEmpty ? NetworkImage(player.avatarUrl) : null,
          child: player.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        const SizedBox(height: 4),
        Text(
          isMe ? AppLocalizations.of(context)!.you : player.displayName,
          style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.green : Colors.blue),
        ),
        Text('${AppLocalizations.of(context)!.score}: ${player.score}', style: const TextStyle(fontSize: 16)),
        if (player.isFinished)
          Text(AppLocalizations.of(context)!.finished, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, Map<String, dynamic> question, int index, int total, player, room) {
    final options = List<String>.from(question['options'] ?? []);
    final correctAnswer = question['correctAnswer'];
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${AppLocalizations.of(context)!.question} ${index + 1}/$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(question['content'] ?? '', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 24),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: _isAnswered ? null : () async {
                setState(() {
                  _isAnswered = true;
                  _selectedAnswer = opt;
                });
                final isCorrect = opt == correctAnswer;
                final scoreDelta = isCorrect ? 10 : 0;
                final isLast = index == (total - 1);
                await ref.read(pvpRoomProvider.notifier).answerQuestionPvp(
                  userId: _userId,
                  answer: opt,
                  scoreDelta: scoreDelta,
                  isLastQuestion: isLast,
                );
                await Future.delayed(const Duration(milliseconds: 800));
                setState(() {
                  _isAnswered = false;
                  _selectedAnswer = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedAnswer == opt
                    ? (opt == correctAnswer ? Colors.green : Colors.red)
                    : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(opt, style: const TextStyle(fontSize: 20)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFinishScreen(BuildContext context, int myScore, int opponentScore) {
    String result;
    if (myScore > opponentScore) {
      result = AppLocalizations.of(context)!.win;
    } else if (myScore < opponentScore) {
      result = AppLocalizations.of(context)!.lose;
    } else {
      result = AppLocalizations.of(context)!.draw;
    }
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(result, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('${AppLocalizations.of(context)!.yourScore(myScore)}', style: const TextStyle(fontSize: 20)),
            Text('${AppLocalizations.of(context)!.score}: $opponentScore', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await ref.read(pvpRoomProvider.notifier).updateRoomStatus(widget.roomId, 'waiting');
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => PvPRoomScreen(roomId: widget.roomId),
                  ),
                  (route) => false,
                );
              },
              child: Text(AppLocalizations.of(context)!.backToMenu),
            ),
          ],
        ),
      ),
    );
  }
} 