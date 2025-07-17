// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Math Clash';

  @override
  String get soloMode => 'Solo Mode';

  @override
  String get createPvpRoom => 'Create PvP Room';

  @override
  String get joinPvpRoom => 'Join PvP Room';

  @override
  String get quickMatch => 'Quick Match';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signOutGoogle => 'Sign out from Google';

  @override
  String get turnOffMusic => 'Turn off background music';

  @override
  String get turnOnMusic => 'Turn on background music';

  @override
  String get soloModeDescription => 'Answer 15 math questions\nThe faster you answer, the more points you get!';

  @override
  String get signInToSaveScore => 'Sign in with Google to save your score to the leaderboard';

  @override
  String get start => 'Start';

  @override
  String get question => 'Question';

  @override
  String get score => 'Score';

  @override
  String timeRemaining(Object seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String get gameCompleted => 'Game completed!';

  @override
  String yourScore(Object score) {
    return 'Your score: $score';
  }

  @override
  String get signInToSave => 'Sign in to save score';

  @override
  String get scoreNotSaved => 'Score will not be saved to leaderboard';

  @override
  String get close => 'Close';

  @override
  String get playAgain => 'Play Again';

  @override
  String get backToMenu => 'Back to Menu';

  @override
  String get roomCode => 'Room Code';

  @override
  String get copyRoomCode => 'Copy room code';

  @override
  String get roomCodeCopied => 'Room code copied!';

  @override
  String get startGame => 'Start Game';

  @override
  String get waitingForPlayers => 'Waiting for other players...';

  @override
  String get enterRoomCode => 'Enter room code to join';

  @override
  String get pleaseEnterRoomCode => 'Please enter room code';

  @override
  String get needGoogleSignIn => 'You need to sign in with Google';

  @override
  String get cannotJoinRoom => 'Cannot join room';

  @override
  String get leaveRoom => 'Leave Room';

  @override
  String get featureInDevelopment => 'Feature in development!';

  @override
  String get error => 'Error';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noLeaderboardData => 'No leaderboard data available';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get signInToSaveLeaderboard => 'Sign in with Google to save score to leaderboard';

  @override
  String get pvpMode => 'PvP Mode';

  @override
  String get soundError => 'Sound playback error';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get about => 'About';

  @override
  String get appDescription => 'Math Clash - A fun math game!';

  @override
  String get languageChanged => 'Language changed!';

  @override
  String get join => 'Join';

  @override
  String get savingScore => 'Saving score...';

  @override
  String get you => 'You';

  @override
  String get waiting => 'Waiting';

  @override
  String get playing => 'Playing';

  @override
  String get finished => 'Finished';

  @override
  String get unknown => 'Unknown';

  @override
  String get leaveRoomConfirm => 'Are you sure you want to leave the room?';

  @override
  String get cancel => 'Cancel';

  @override
  String get leavingRoom => 'Leaving room...';

  @override
  String get leaveRoomError => 'An error occurred while leaving the room';

  @override
  String get creatingRoom => 'Creating room...';

  @override
  String get pleaseSignInGoogle => 'Please sign in with Google to save score';

  @override
  String get errorSavingScore => 'Error saving score';

  @override
  String get roomNotExists => 'Room does not exist!';

  @override
  String get roomFull => 'Room is full!';

  @override
  String get googleSignInTimeout => 'Google sign in timeout, please try again!';

  @override
  String get errorGoogleSignIn => 'Error signing in with Google';

  @override
  String get errorGoogleSignOut => 'Error signing out';

  @override
  String get players => 'Players';

  @override
  String get playersInRoom => 'Players in room';
}
