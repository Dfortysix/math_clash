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
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header giống solo mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.question} '
                  '${(_currentQuestionIndex + 1 > totalQuestions ? totalQuestions : _currentQuestionIndex + 1)}/$totalQuestions',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${AppLocalizations.of(context)!.score}: $myScore',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTimeColor(_time),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.timeRemaining(_time.toString()),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPlayerInfo(context, me, isMe: true),
                _buildPlayerInfo(context, opponent, isMe: false),
              ],
            ),
            const SizedBox(height: 16),
            if (_showResult)
              _buildFinishScreen(context, myScore, opponentScore)
            else if (isGameOver)
              Center(child: Text(AppLocalizations.of(context)!.waitingForOpponent))
            else
              _buildQuestion(context, questions[_currentQuestionIndex] as Map<String, dynamic>, _currentQuestionIndex, totalQuestions, me, room),
          ],
        ),
      ),
    );
  }

  bool _isFinishedOrNull(bool isFinished, dynamic currentQuestion) {
    return isFinished || currentQuestion == null;
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
        Text(
          isMe
              ? '${AppLocalizations.of(context)!.score}: $_score'
              : '${AppLocalizations.of(context)!.score}: ${player.score}',
          style: const TextStyle(fontSize: 16),
        ),
        if (player.isFinished)
          Text(AppLocalizations.of(context)!.finished, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, Map<String, dynamic> question, int index, int total, player, room) {
    final options = List<String>.from(question['options'] ?? []);
    final correctAnswer = question['correctAnswer'];
    final difficulty = (question['difficulty'] ?? 1) is int ? question['difficulty'] ?? 1 : (question['difficulty'] ?? 1).toInt();
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Khung câu hỏi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              question['content'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
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
                }

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: opacity,
                  child: SizedBox.expand(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: ElevatedButton(
                            onPressed: (_isAnimating || _selectedAnswer != null)
                                ? null
                                : () async {
                                    final isCorrect = opt == correctAnswer;
                                    setState(() {
                                      _selectedAnswer = opt;
                                      _isCorrect = isCorrect;
                                      _isAnimating = true;
                                    });
                                    await _playAnswerSound(isCorrect);
                                    await Future.delayed(const Duration(milliseconds: 900));
                                    int scoreDelta = 0;
                                    if (isCorrect) {
                                      final int baseScore = 10;
                                      final int diffInt = difficulty is int ? difficulty : (difficulty as num).toInt();
                                      final int timeBonus = (_time / 5).round().toInt();
                                      scoreDelta = baseScore * diffInt * timeBonus;
                                    }
                                    setState(() {
                                      _score += scoreDelta;
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
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(color: Color(0xFF0ED2F7), width: 2),
                              ),
                              elevation: 6,
                              shadowColor: Colors.black12,
                              splashFactory: InkRipple.splashFactory,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(opt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                        if (showTick)
                          const Positioned(
                            right: 12,
                            top: 12,
                            child: Icon(Icons.check_circle, color: Colors.green, size: 32),
                          ),
                        if (showCross)
                          const Positioned(
                            right: 12,
                            top: 12,
                            child: Icon(Icons.cancel, color: Colors.red, size: 32),
                          ),
                      ],
                    ),
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