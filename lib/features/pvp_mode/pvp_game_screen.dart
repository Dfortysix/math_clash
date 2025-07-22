import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvp_room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'pvp_room_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class PvPGameScreen extends ConsumerStatefulWidget {
  final String roomId;
  const PvPGameScreen({super.key, required this.roomId});

  @override
  ConsumerState<PvPGameScreen> createState() => _PvPGameScreenState();
}

class _PvPGameScreenState extends ConsumerState<PvPGameScreen> {
  static const int questionTimeLimit = 10;
  int _time = questionTimeLimit;
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnimating = false;
  String? _selectedAnswer;
  bool? _isCorrect;
  Timer? _timer;
  bool _timerActive = false;
  final AudioPlayer _fxPlayer = AudioPlayer();
  late final String _userId;
  bool _isFinished = false;
  DateTime? _startTime;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final user = ref.read(authProvider).user;
    _userId = user?.uid ?? '';
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _fxPlayer.dispose();
    super.dispose();
  }

  void _startTimer(VoidCallback onTimeout) {
    if (_timerActive) return;
    _timer?.cancel();
    setState(() {
      _time = questionTimeLimit;
      _timerActive = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_time <= 1) {
        timer.cancel();
        setState(() {
          _timerActive = false;
        });
        onTimeout();
      } else {
        setState(() {
          _time--;
        });
      }
    });
  }

  Future<void> _playAnswerSound(bool isCorrect) async {
    final file = isCorrect ? 'sounds/correct_answer.mp3' : 'sounds/wrong_answer.mp3';
    try {
      await _fxPlayer.stop();
      await _fxPlayer.setVolume(7.0);
      await _fxPlayer.play(AssetSource(file));
    } catch (e) {
      print('Lỗi phát âm thanh: $e');
    }
  }

  Color _getTimeColor(int timeRemaining) {
    if (timeRemaining > 7) return Colors.green;
    if (timeRemaining > 3) return Colors.orange;
    return Colors.red;
  }

  void _finishGame(BuildContext context, int totalQuestions) async {
    setState(() {
      _isFinished = true;
    });
    // Cập nhật trạng thái finish lên Firestore
    await ref.read(pvpRoomProvider.notifier).answerQuestionPvp(
      userId: _userId,
      answer: '',
      scoreDelta: 0,
      isLastQuestion: true,
    );
    // Kiểm tra trạng thái đối thủ để show kết quả
    _waitForOpponentOrTimeout(context, totalQuestions);
  }

  void _waitForOpponentOrTimeout(BuildContext context, int totalQuestions) async {
    final roomProvider = ref.read(pvpRoomProvider.notifier);
    final totalTime = totalQuestions * questionTimeLimit;
    final start = _startTime ?? DateTime.now();
    final endTime = start.add(Duration(seconds: totalTime));
    while (true) {
      final now = DateTime.now();
      final room = ref.read(pvpRoomProvider).room;
      if (room != null) {
        final allFinished = room.players.every((p) => p.isFinished);
        if (allFinished || now.isAfter(endTime)) {
          setState(() {
            _showResult = true;
          });
          break;
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }
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
    final totalQuestions = questions.length;
    final myScore = _score;
    final opponentScore = opponent.score;
    final isGameOver = _isFinished || _currentQuestionIndex >= totalQuestions;

    // Chỉ khởi động timer khi sang câu mới và không có timer nào đang chạy
    if (!isGameOver && !_isAnimating && _selectedAnswer == null && !_timerActive) {
      _startTimer(() async {
        setState(() {
          _selectedAnswer = '';
          _isCorrect = false;
          _isAnimating = true;
        });
        await _playAnswerSound(false);
        await Future.delayed(const Duration(milliseconds: 900));
        setState(() {
          _selectedAnswer = null;
          _isCorrect = null;
          _isAnimating = false;
          _currentQuestionIndex++;
          _timer?.cancel();
          _timerActive = false;
          if (_currentQuestionIndex >= totalQuestions) {
            _finishGame(context, totalQuestions);
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pvpMode),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9),
              Color(0xFFA5D6A7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header đẹp hơn
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.question_answer, color: Colors.green, size: 24),
                      const SizedBox(width: 6),
                      Text(
                        '${AppLocalizations.of(context)!.question} '
                        '${(_currentQuestionIndex + 1 > totalQuestions ? totalQuestions : _currentQuestionIndex + 1)}/$totalQuestions',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 10),
                      IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _getTimeColor(_time),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.white, size: 18),
                              const SizedBox(width: 2),
                              Text(
                                AppLocalizations.of(context)!.timeRemaining(_time.toString()),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Avatars
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: _buildPlayerInfo(context, me, isMe: true, avatarSize: 48)),
                    const SizedBox(width: 8),
                    Flexible(child: _buildPlayerInfo(context, opponent, isMe: false, avatarSize: 48)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_showResult)
                _buildFinishScreen(context, myScore, opponentScore)
              else
                (isGameOver
                  ? Center(child: Text(AppLocalizations.of(context)!.waitingForOpponent, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)))
                  : _buildQuestion(context, questions[_currentQuestionIndex] as Map<String, dynamic>, _currentQuestionIndex, totalQuestions, me, room)),
            ],
          ),
        ),
      ),
    );
  }

  bool _isFinishedOrNull(bool isFinished, dynamic currentQuestion) {
    return isFinished || currentQuestion == null;
  }

  Widget _buildPlayerInfo(BuildContext context, player, {required bool isMe, double avatarSize = 50}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundImage: player.avatarUrl.isNotEmpty ? NetworkImage(player.avatarUrl) : null,
          child: player.avatarUrl.isEmpty ? const Icon(Icons.person, size: 28) : null,
        ),
        const SizedBox(height: 4),
        Text(
          isMe ? AppLocalizations.of(context)!.you : player.displayName,
          style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.green : Colors.blue, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          isMe
              ? '${AppLocalizations.of(context)!.score}: $_score'
              : '${AppLocalizations.of(context)!.score}: ${player.score}',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (player.isFinished)
          Text(AppLocalizations.of(context)!.finished, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, Map<String, dynamic> question, int index, int total, player, room) {
    final options = List<String>.from(question['options'] ?? []);
    final correctAnswer = question['correctAnswer'];
    final difficultyRaw = question['difficulty'] ?? 1;
    final int difficulty = difficultyRaw is int ? difficultyRaw : (difficultyRaw as num).toInt();
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Khung câu hỏi nổi bật
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              question['content'] ?? '',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 36),
          // Đáp án
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemCount: options.length,
              itemBuilder: (context, idx) {
                final opt = options[idx];
                final isSelected = _selectedAnswer == opt;
                final isCorrectAnswer = opt == correctAnswer;
                bool showTick = false;
                bool showCross = false;
                double opacity = 1.0;
                Color bgColor = const Color(0xFFF6FCFF);

                if (_selectedAnswer != null && _isAnimating) {
                  if (_isCorrect == true) {
                    if (isCorrectAnswer) {
                      showTick = true;
                      bgColor = Colors.green.shade100;
                    } else {
                      opacity = 0.5;
                    }
                  } else {
                    if (isSelected) {
                      showCross = true;
                      bgColor = Colors.red.shade100;
                    } else if (isCorrectAnswer) {
                      showTick = true;
                      bgColor = Colors.green.shade100;
                    } else {
                      opacity = 0.5;
                    }
                  }
                } else if (isSelected) {
                  bgColor = Colors.green.shade50;
                }

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: opacity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ElevatedButton(
                          onPressed: (_isAnimating || _selectedAnswer != null)
                              ? null
                              : () async {
                                  setState(() {
                                    _selectedAnswer = opt;
                                    _isCorrect = isCorrectAnswer;
                                    _isAnimating = true;
                                  });
                                  await _playAnswerSound(isCorrectAnswer);
                                  await Future.delayed(const Duration(milliseconds: 900));
                                  int timeBonus = (_time / 5).round();
                                  int baseScore = 10;
                                  int scoreDelta = baseScore * difficulty * timeBonus;
                                  if (isCorrectAnswer) {
                                    setState(() {
                                      _score += scoreDelta;
                                    });
                                  }
                                  await ref.read(pvpRoomProvider.notifier).answerQuestionPvp(
                                    userId: _userId,
                                    answer: opt,
                                    scoreDelta: isCorrectAnswer ? scoreDelta : 0,
                                    isLastQuestion: _currentQuestionIndex + 1 >= total,
                                  );
                                  setState(() {
                                    _selectedAnswer = null;
                                    _isCorrect = null;
                                    _isAnimating = false;
                                    _currentQuestionIndex++;
                                    _timer?.cancel();
                                    _timerActive = false;
                                    if (_currentQuestionIndex >= total) {
                                      _finishGame(context, total);
                                    }
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bgColor,
                            foregroundColor: const Color(0xFF0052D4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: isSelected ? Colors.green : const Color(0xFF0ED2F7), width: 2),
                            ),
                            elevation: 8,
                            shadowColor: Colors.greenAccent.withOpacity(0.15),
                            splashFactory: InkRipple.splashFactory,
                          ),
                          child: Text(
                            opt,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                      ),
                      if (showTick)
                        const Positioned(
                          right: 14,
                          top: 14,
                          child: Icon(Icons.check_circle, color: Colors.green, size: 34),
                        ),
                      if (showCross)
                        const Positioned(
                          right: 14,
                          top: 14,
                          child: Icon(Icons.cancel, color: Colors.red, size: 34),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
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