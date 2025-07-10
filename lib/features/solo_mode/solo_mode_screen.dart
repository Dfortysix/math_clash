import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../models/question.dart';
import '../../providers/solo_mode_provider.dart';
import '../../providers/leaderboard_provider.dart';

class SoloModeScreen extends StatefulWidget {
  const SoloModeScreen({super.key});

  @override
  State<SoloModeScreen> createState() => _SoloModeScreenState();
}

class _SoloModeScreenState extends State<SoloModeScreen> {
  Timer? _timer;
  static const int questionTimeLimit = 10; // 10 giây cho mỗi câu

  String? _selectedAnswer;
  bool? _isCorrect;
  bool _isAnimating = false;
  bool _hasShownSaveDialog = false; // Flag để tránh hiển thị dialog nhiều lần
  bool _hasResetState = false; // Flag để kiểm tra đã reset state chưa
  final AudioPlayer _fxPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fxPlayer.setReleaseMode(ReleaseMode.stop);
    _fxPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    
    // Reset trạng thái khi vào màn hình mới
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetGameState();
    });
  }

  void _resetGameState() {
    _timer?.cancel();
    _selectedAnswer = null;
    _isCorrect = null;
    _isAnimating = false;
    _hasShownSaveDialog = false;
    _hasResetState = false;
  }

  void _resetProviderState(WidgetRef ref) {
    ref.read(soloModeProvider.notifier).resetToInitialState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fxPlayer.dispose();
    super.dispose();
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

  void _startTimer(WidgetRef ref) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final notifier = ref.read(soloModeProvider.notifier);
      final currentState = ref.read(soloModeProvider);
      
      if (currentState.timeRemaining <= 0) {
        // Hết thời gian, tự động chuyển câu
        notifier.answerQuestion(''); // Trả lời sai
        _resetTimer(ref);
      } else {
        notifier.updateTimeRemaining(currentState.timeRemaining - 1);
      }
    });
  }

  void _resetTimer(WidgetRef ref) {
    _timer?.cancel();
    ref.read(soloModeProvider.notifier).updateTimeRemaining(questionTimeLimit);
    _startTimer(ref);
  }

  void _startNewGame(WidgetRef ref) {
    ref.read(soloModeProvider.notifier).startNewGame();
    _resetTimer(ref);
    _hasShownSaveDialog = false; // Reset flag khi bắt đầu game mới
  }

  void _onAnswerTap(WidgetRef ref, String option, String correctAnswer) async {
    if (_isAnimating) return;
    final isCorrect = option == correctAnswer;
    setState(() {
      _selectedAnswer = option;
      _isCorrect = isCorrect;
      _isAnimating = true;
    });
    await _playAnswerSound(isCorrect);
    await Future.delayed(const Duration(milliseconds: 900));
    ref.read(soloModeProvider.notifier).answerQuestion(option);
    _resetTimer(ref);
    setState(() {
      _selectedAnswer = null;
      _isCorrect = null;
      _isAnimating = false;
    });
  }

  Future<void> _showSaveScoreDialog(WidgetRef ref, int score) async {
    final TextEditingController nameController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lưu điểm số'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Điểm số của bạn: $score'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nhập tên của bạn',
                  border: OutlineInputBorder(),
                ),
                maxLength: 20,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('Người dùng bỏ qua lưu điểm');
                Navigator.of(context).pop();
              },
              child: const Text('Bỏ qua'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = nameController.text.trim();
                print('Đang lưu điểm: username=$username, score=$score');
                if (username.isNotEmpty) {
                  try {
                    await ref.read(leaderboardProvider.notifier).saveScore(username, score, 'solo');
                    print('Đã lưu điểm thành công!');
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Lỗi khi lưu điểm: $e');
                    // Hiển thị thông báo lỗi
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi lưu điểm: $e')),
                    );
                  }
                } else {
                  print('Username trống, không lưu điểm');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên của bạn')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solo Mode'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
        child: Consumer(
          builder: (context, ref, child) {
            final soloState = ref.watch(soloModeProvider);
            
            // Reset provider state một lần duy nhất khi vào màn hình
            if (!_hasResetState) {
              _hasResetState = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _resetProviderState(ref);
              });
            }
            
            if (soloState.questions.isEmpty) {
              return _buildStartScreen(ref);
            }
            
            if (soloState.isGameOver) {
              _timer?.cancel();
              // Hiển thị dialog lưu điểm khi game over (chỉ hiển thị một lần)
              if (!_hasShownSaveDialog) {
                _hasShownSaveDialog = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  print('Game over, hiển thị dialog lưu điểm với score: ${soloState.score}');
                  _showSaveScoreDialog(ref, soloState.score);
                });
              }
              return _buildGameOverScreen(ref, soloState);
            }
            
            return _buildGameScreen(ref, soloState);
          },
        ),
      ),
    );
  }

  Widget _buildStartScreen(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Solo Mode',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Trả lời 15 câu hỏi toán học\nCàng nhanh càng được nhiều điểm!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _startNewGame(ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              'Bắt đầu',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen(WidgetRef ref, SoloModeState state) {
    final currentQuestion = state.questions[state.currentQuestionIndex];
    final correctAnswer = currentQuestion.correctAnswer;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header với thông tin game
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu ${state.currentQuestionIndex + 1}/15',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Điểm: ${state.score}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Thời gian còn lại với màu sắc thay đổi
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getTimeColor(state.timeRemaining),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Thời gian: ${state.timeRemaining}s',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 40),
          
          // Câu hỏi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              currentQuestion.content,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          
          // Các lựa chọn
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                final option = currentQuestion.options[index];
                final isSelected = _selectedAnswer == option;
                final isCorrectAnswer = option == correctAnswer;
                bool showTick = false;
                bool showCross = false;
                double opacity = 1.0;
                Color bgColor = const Color(0xFFF6FCFF);

                if (_selectedAnswer != null && _isAnimating) {
                  // Đã chọn đáp án
                  if (_isCorrect == true) {
                    // Đúng: chỉ đáp án đúng hiện tick, các đáp án khác mờ
                    if (isCorrectAnswer) {
                      showTick = true;
                      bgColor = Colors.green.shade100;
                    } else {
                      opacity = 0.5;
                    }
                  } else {
                    // Sai: đáp án chọn hiện X, đáp án đúng hiện tick, còn lại mờ
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
                                : () => _onAnswerTap(ref, option, correctAnswer),
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
                            ),
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
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

  Widget _buildGameOverScreen(WidgetRef ref, SoloModeState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Đổi từ 'Game Over!' sang thông báo điểm
          Text(
            'Bạn đã hoàn thành!\nSố điểm: ${state.score}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _startNewGame(ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              'Chơi lại',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimeColor(int timeRemaining) {
    if (timeRemaining > 20) return Colors.green;
    if (timeRemaining > 10) return Colors.orange;
    return Colors.red;
  }
} 