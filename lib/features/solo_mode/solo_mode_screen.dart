import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../models/question.dart';
import '../../providers/solo_mode_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.soloMode),
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
            final authState = ref.watch(authProvider);
            
            // Reset provider state một lần duy nhất khi vào màn hình
            if (!_hasResetState) {
              _hasResetState = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _resetProviderState(ref);
              });
            }
            
            // Hiển thị thông báo lỗi lưu điểm
            if (soloState.saveScoreError != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(soloState.saveScoreError!),
                    backgroundColor: Colors.orange,
                    action: SnackBarAction(
                      label: AppLocalizations.of(context)!.close,
                      textColor: Colors.white,
                      onPressed: () {
                        ref.read(soloModeProvider.notifier).clearSaveScoreError();
                      },
                    ),
                  ),
                );
              });
            }
            
            if (soloState.questions.isEmpty) {
              return _buildStartScreen(ref, authState);
            }
            
            if (soloState.isGameOver) {
              _timer?.cancel();
              return _buildGameOverScreen(ref, soloState, authState);
            }
            
            return _buildGameScreen(ref, soloState);
          },
        ),
      ),
    );
  }

  Widget _buildStartScreen(WidgetRef ref, AuthState authState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.soloMode,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.soloModeDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          
          // Hiển thị trạng thái đăng nhập Google
          if (!authState.isGoogleSignedIn)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.signInToSaveScore,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _startNewGame(ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text(
              AppLocalizations.of(context)!.start,
              style: const TextStyle(fontSize: 20),
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
                '${AppLocalizations.of(context)!.question} ${state.currentQuestionIndex + 1}/15',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${AppLocalizations.of(context)!.score}: ${state.score}',
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
              AppLocalizations.of(context)!.timeRemaining(state.timeRemaining.toString()),
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

  Widget _buildGameOverScreen(WidgetRef ref, SoloModeState state, AuthState authState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Thông báo điểm
          Text(
            AppLocalizations.of(context)!.gameCompleted,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          
          const SizedBox(height: 20),
          
          // Hiển thị trạng thái lưu điểm
          if (state.isSavingScore)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.savingScore,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          
          // Hiển thị thông báo khi chưa đăng nhập Google
          if (!authState.isGoogleSignedIn && !state.isSavingScore)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.signInToSave,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.scoreNotSaved,
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _startNewGame(ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text(
              AppLocalizations.of(context)!.playAgain,
              style: const TextStyle(fontSize: 20),
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