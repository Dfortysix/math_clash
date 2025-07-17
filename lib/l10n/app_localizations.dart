import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Math Clash'**
  String get appTitle;

  /// No description provided for @soloMode.
  ///
  /// In en, this message translates to:
  /// **'Solo Mode'**
  String get soloMode;

  /// No description provided for @createPvpRoom.
  ///
  /// In en, this message translates to:
  /// **'Create PvP Room'**
  String get createPvpRoom;

  /// No description provided for @joinPvpRoom.
  ///
  /// In en, this message translates to:
  /// **'Join PvP Room'**
  String get joinPvpRoom;

  /// No description provided for @quickMatch.
  ///
  /// In en, this message translates to:
  /// **'Quick Match'**
  String get quickMatch;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInGoogle;

  /// No description provided for @signOutGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from Google'**
  String get signOutGoogle;

  /// No description provided for @turnOffMusic.
  ///
  /// In en, this message translates to:
  /// **'Turn off background music'**
  String get turnOffMusic;

  /// No description provided for @turnOnMusic.
  ///
  /// In en, this message translates to:
  /// **'Turn on background music'**
  String get turnOnMusic;

  /// No description provided for @soloModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Answer 15 math questions\nThe faster you answer, the more points you get!'**
  String get soloModeDescription;

  /// No description provided for @signInToSaveScore.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to save your score to the leaderboard'**
  String get signInToSaveScore;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time: {seconds}s'**
  String timeRemaining(Object seconds);

  /// No description provided for @gameCompleted.
  ///
  /// In en, this message translates to:
  /// **'Game completed!'**
  String get gameCompleted;

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'Your score: {score}'**
  String yourScore(Object score);

  /// No description provided for @signInToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save score'**
  String get signInToSave;

  /// No description provided for @scoreNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Score will not be saved to leaderboard'**
  String get scoreNotSaved;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get backToMenu;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room Code'**
  String get roomCode;

  /// No description provided for @copyRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Copy room code'**
  String get copyRoomCode;

  /// No description provided for @roomCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Room code copied!'**
  String get roomCodeCopied;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for other players...'**
  String get waitingForPlayers;

  /// No description provided for @enterRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Enter room code to join'**
  String get enterRoomCode;

  /// No description provided for @pleaseEnterRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter room code'**
  String get pleaseEnterRoomCode;

  /// No description provided for @needGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in with Google'**
  String get needGoogleSignIn;

  /// No description provided for @cannotJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Cannot join room'**
  String get cannotJoinRoom;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave Room'**
  String get leaveRoom;

  /// No description provided for @featureInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Feature in development!'**
  String get featureInDevelopment;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noLeaderboardData.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard data available'**
  String get noLeaderboardData;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @signInToSaveLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to save score to leaderboard'**
  String get signInToSaveLeaderboard;

  /// No description provided for @pvpMode.
  ///
  /// In en, this message translates to:
  /// **'PvP Mode'**
  String get pvpMode;

  /// No description provided for @soundError.
  ///
  /// In en, this message translates to:
  /// **'Sound playback error'**
  String get soundError;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Math Clash - A fun math game!'**
  String get appDescription;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed!'**
  String get languageChanged;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @savingScore.
  ///
  /// In en, this message translates to:
  /// **'Saving score...'**
  String get savingScore;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @leaveRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave the room?'**
  String get leaveRoomConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @leavingRoom.
  ///
  /// In en, this message translates to:
  /// **'Leaving room...'**
  String get leavingRoom;

  /// No description provided for @leaveRoomError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while leaving the room'**
  String get leaveRoomError;

  /// No description provided for @creatingRoom.
  ///
  /// In en, this message translates to:
  /// **'Creating room...'**
  String get creatingRoom;

  /// No description provided for @pleaseSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in with Google to save score'**
  String get pleaseSignInGoogle;

  /// No description provided for @errorSavingScore.
  ///
  /// In en, this message translates to:
  /// **'Error saving score'**
  String get errorSavingScore;

  /// No description provided for @roomNotExists.
  ///
  /// In en, this message translates to:
  /// **'Room does not exist!'**
  String get roomNotExists;

  /// No description provided for @roomFull.
  ///
  /// In en, this message translates to:
  /// **'Room is full!'**
  String get roomFull;

  /// No description provided for @googleSignInTimeout.
  ///
  /// In en, this message translates to:
  /// **'Google sign in timeout, please try again!'**
  String get googleSignInTimeout;

  /// No description provided for @errorGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Error signing in with Google'**
  String get errorGoogleSignIn;

  /// No description provided for @errorGoogleSignOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out'**
  String get errorGoogleSignOut;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @playersInRoom.
  ///
  /// In en, this message translates to:
  /// **'Players in room'**
  String get playersInRoom;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @roomHost.
  ///
  /// In en, this message translates to:
  /// **'Room Host'**
  String get roomHost;

  /// No description provided for @sounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get sounds;

  /// No description provided for @settings_developer.
  ///
  /// In en, this message translates to:
  /// **'Developer:'**
  String get settings_developer;

  /// No description provided for @settings_developer_name.
  ///
  /// In en, this message translates to:
  /// **'Nguyen Tri Dung'**
  String get settings_developer_name;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
