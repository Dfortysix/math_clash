import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'services/google_play_games_service.dart';
import 'providers/auth_provider.dart';
import 'features/solo_mode/solo_mode_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/pvp_mode/create_room_screen.dart';
import 'features/pvp_mode/join_room_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khóa xoay màn hình chỉ cho phép portrait (dọc)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await FirebaseService.initialize();
  
  // Kiểm tra cấu hình Firebase
  final isConfigured = await FirebaseService.checkFirebaseConfiguration();
  print('Main: Firebase configuration check: $isConfigured');
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AudioPlayer _audioPlayer;
  bool _isMusicPlaying = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/background_music.mp3'));
    setState(() {
      _isMusicPlaying = true;
    });
  }

  Future<void> _pauseMusic() async {
    await _audioPlayer.pause();
    setState(() {
      _isMusicPlaying = false;
    });
  }

  Future<void> _resumeMusic() async {
    await _audioPlayer.resume();
    setState(() {
      _isMusicPlaying = true;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Clash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('vi'),
      ],
      // home: HomeScreen( ... ) bị xóa để tránh conflict với route '/'
      routes: {
        '/': (context) => HomeScreen(
          isMusicPlaying: _isMusicPlaying,
          onToggleMusic: () {
            if (_isMusicPlaying) {
              _pauseMusic();
            } else {
              _resumeMusic();
            }
          },
        ),
        '/solo': (context) => const SoloModeScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class HomeScreen extends ConsumerWidget {
  final bool isMusicPlaying;
  final VoidCallback onToggleMusic;
  const HomeScreen({super.key, required this.isMusicPlaying, required this.onToggleMusic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isMusicPlaying ? Icons.music_note : Icons.music_off),
            tooltip: isMusicPlaying
                ? AppLocalizations.of(context)!.turnOffMusic
                : AppLocalizations.of(context)!.turnOnMusic,
            onPressed: onToggleMusic,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context)!.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.15),
          ),
          Center(
            child: Container(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Math Clash',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 40),
                  
                  // Hiển thị thông tin user nếu đã đăng nhập
                  if (authState.isGoogleSignedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (authState.user?.photoURL != null)
                            CircleAvatar(
                              backgroundImage: NetworkImage(authState.user!.photoURL!),
                              radius: 20,
                            ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.user?.displayName ?? 'User',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                authState.user?.email ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.person),
                      label: Text(AppLocalizations.of(context)!.soloMode, style: TextStyle(fontSize: 20)),
                      onPressed: () {
                        Navigator.pushNamed(context, '/solo');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.meeting_room),
                      label: Text(AppLocalizations.of(context)!.createPvpRoom, style: TextStyle(fontSize: 20)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const CreateRoomScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.input),
                      label: Text(AppLocalizations.of(context)!.joinPvpRoom, style: TextStyle(fontSize: 20)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const JoinRoomScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.flash_on),
                      label: Text(AppLocalizations.of(context)!.quickMatch, style: TextStyle(fontSize: 20)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.featureInDevelopment)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.leaderboard),
                      label: Text(AppLocalizations.of(context)!.leaderboard, style: TextStyle(fontSize: 20)),
                      onPressed: () {
                        Navigator.pushNamed(context, '/leaderboard');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  // Nút đăng nhập/đăng xuất Google
                  if (authState.isGoogleSignedIn)
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : () async {
                        await ref.read(authProvider.notifier).signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              AppLocalizations.of(context)!.signOutGoogle,
                              style: TextStyle(fontSize: 20),
                            ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          try {
                            await ref.read(authProvider.notifier).signInWithGoogle().timeout(
                              const Duration(seconds: 30),
                              onTimeout: () {
                                throw Exception('Đăng nhập Google quá lâu, vui lòng thử lại!');
                              },
                            );
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text(e.toString(), style: const TextStyle(fontSize: 16))),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                AppLocalizations.of(context)!.signInGoogle,
                                style: TextStyle(fontSize: 20),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
