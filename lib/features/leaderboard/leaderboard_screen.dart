import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/leaderboard_entry.dart';
import '../../l10n/app_localizations.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardProvider.notifier).loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.leaderboard),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(leaderboardProvider.notifier).loadLeaderboard();
            },
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
        child: Column(
          children: [
            // Hiển thị thông tin user nếu đã đăng nhập
            if (authState.isGoogleSignedIn) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (authState.user?.photoURL != null)
                      CircleAvatar(
                        backgroundImage: NetworkImage(authState.user!.photoURL!),
                        radius: 20,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.user?.displayName ?? 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            authState.user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.signedIn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Thông báo khi chưa đăng nhập Google
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.notSignedIn,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.signInToSaveLeaderboard,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Game Mode Selector
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeButton(AppLocalizations.of(context)!.soloMode, 'solo', leaderboardState.selectedGameMode),
                  _buildModeButton(AppLocalizations.of(context)!.pvpMode, 'pvp', leaderboardState.selectedGameMode),
                ],
              ),
            ),
            
            // Leaderboard Content
            Expanded(
              child: leaderboardState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : leaderboardState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                '${AppLocalizations.of(context)!.error}: ${leaderboardState.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(leaderboardProvider.notifier).loadLeaderboard();
                                },
                                child: Text(AppLocalizations.of(context)!.tryAgain),
                              ),
                            ],
                          ),
                        )
                      : leaderboardState.entries.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.emoji_events, size: 64, color: Colors.orange),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!.noLeaderboardData,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: leaderboardState.entries.length,
                              itemBuilder: (context, index) {
                                final entry = leaderboardState.entries[index];
                                return _buildLeaderboardItem(entry, index + 1);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String title, String mode, String selectedMode) {
    final isSelected = selectedMode == mode;
    return ElevatedButton(
      onPressed: () {
        ref.read(leaderboardProvider.notifier).changeGameMode(mode);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(title),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int rank) {
    final isTop3 = rank <= 3;
    final rankColors = [
      Colors.amber, // Gold
      Colors.grey[400]!, // Silver
      Colors.brown, // Bronze
    ];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isTop3 ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundColor: isTop3 ? rankColors[rank - 1] : Colors.blue.shade100,
              radius: 24,
              child: entry.avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        entry.avatarUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 32),
                      ),
                    )
                  : const Icon(Icons.person, size: 32, color: Colors.white),
            ),
            if (isTop3)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rankColors[rank - 1],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          entry.username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text('${AppLocalizations.of(context)!.score}: ${entry.score}'),
        trailing: Text(
          '#$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isTop3 ? rankColors[rank - 1] : Colors.blue,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 