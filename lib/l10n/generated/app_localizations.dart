import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get play;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get tryAgain;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get home;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @hardcore.
  ///
  /// In en, this message translates to:
  /// **'Hardcore'**
  String get hardcore;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @howToPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get howToPlayTitle;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareScore.
  ///
  /// In en, this message translates to:
  /// **'Share score'**
  String get shareScore;

  /// No description provided for @shareGame.
  ///
  /// In en, this message translates to:
  /// **'Share Atomic Orbital'**
  String get shareGame;

  /// No description provided for @trophies.
  ///
  /// In en, this message translates to:
  /// **'Trophies'**
  String get trophies;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @scores.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get scores;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @playGames.
  ///
  /// In en, this message translates to:
  /// **'Play Games'**
  String get playGames;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Play Games'**
  String get disconnect;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @controls.
  ///
  /// In en, this message translates to:
  /// **'Hold to move out · Release to move in'**
  String get controls;

  /// No description provided for @oneHit.
  ///
  /// In en, this message translates to:
  /// **'One hit. Game over.'**
  String get oneHit;

  /// No description provided for @regenerates.
  ///
  /// In en, this message translates to:
  /// **'Health regenerates.'**
  String get regenerates;

  /// No description provided for @worldShop.
  ///
  /// In en, this message translates to:
  /// **'World shop'**
  String get worldShop;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'GAME OVER'**
  String get gameOver;

  /// No description provided for @pickupsCollected.
  ///
  /// In en, this message translates to:
  /// **'PICKUPS COLLECTED'**
  String get pickupsCollected;

  /// No description provided for @newBest.
  ///
  /// In en, this message translates to:
  /// **'NEW BEST!'**
  String get newBest;

  /// No description provided for @personalBest.
  ///
  /// In en, this message translates to:
  /// **'Personal best'**
  String get personalBest;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get paused;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resume;

  /// No description provided for @soundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get soundOff;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get soundOn;

  /// No description provided for @enableSound.
  ///
  /// In en, this message translates to:
  /// **'Enable sound'**
  String get enableSound;

  /// No description provided for @muteSound.
  ///
  /// In en, this message translates to:
  /// **'Mute sound'**
  String get muteSound;

  /// No description provided for @endRun.
  ///
  /// In en, this message translates to:
  /// **'End run'**
  String get endRun;

  /// No description provided for @endRunLabel.
  ///
  /// In en, this message translates to:
  /// **'End run and return to menu'**
  String get endRunLabel;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'GOT IT'**
  String get gotIt;

  /// No description provided for @holdRelease.
  ///
  /// In en, this message translates to:
  /// **'Hold out, release in'**
  String get holdRelease;

  /// No description provided for @holdHelp.
  ///
  /// In en, this message translates to:
  /// **'Hold in the arena or hold Space/Enter to move outward. Release to move inward.'**
  String get holdHelp;

  /// No description provided for @collectPickups.
  ///
  /// In en, this message translates to:
  /// **'Collect pickups'**
  String get collectPickups;

  /// No description provided for @collectHelp.
  ///
  /// In en, this message translates to:
  /// **'Each pickup scores one point and reverses your direction.'**
  String get collectHelp;

  /// No description provided for @avoidHazards.
  ///
  /// In en, this message translates to:
  /// **'Avoid red hazards'**
  String get avoidHazards;

  /// No description provided for @hazardHelp.
  ///
  /// In en, this message translates to:
  /// **'Normal mode regenerates health. Hardcore ends on the first hit.'**
  String get hazardHelp;

  /// No description provided for @takeBreak.
  ///
  /// In en, this message translates to:
  /// **'Take a break'**
  String get takeBreak;

  /// No description provided for @pauseHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the pause button, Escape/P or Android Back. Resume when you’re ready.'**
  String get pauseHelp;

  /// No description provided for @pauseGame.
  ///
  /// In en, this message translates to:
  /// **'Pause game'**
  String get pauseGame;

  /// No description provided for @touchToStart.
  ///
  /// In en, this message translates to:
  /// **'TOUCH TO START'**
  String get touchToStart;

  /// No description provided for @holdLabel.
  ///
  /// In en, this message translates to:
  /// **'Hold to move outward; release to move inward.'**
  String get holdLabel;

  /// No description provided for @readyLabel.
  ///
  /// In en, this message translates to:
  /// **'Touch or press Space to start. Hold to move outward; release to move inward.'**
  String get readyLabel;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @nextGoal.
  ///
  /// In en, this message translates to:
  /// **'Next goal'**
  String get nextGoal;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @allComplete.
  ///
  /// In en, this message translates to:
  /// **'All achievements earned'**
  String get allComplete;

  /// No description provided for @completedRuns.
  ///
  /// In en, this message translates to:
  /// **'Completed runs'**
  String get completedRuns;

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Points in completed runs'**
  String get totalPoints;

  /// No description provided for @playTime.
  ///
  /// In en, this message translates to:
  /// **'Recorded playtime'**
  String get playTime;

  /// No description provided for @worldsOwned.
  ///
  /// In en, this message translates to:
  /// **'Worlds owned'**
  String get worldsOwned;

  /// No description provided for @normalBest.
  ///
  /// In en, this message translates to:
  /// **'Normal best'**
  String get normalBest;

  /// No description provided for @hardcoreBest.
  ///
  /// In en, this message translates to:
  /// **'Hardcore best'**
  String get hardcoreBest;

  /// No description provided for @localProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress is saved on this device. Uninstalling or clearing app data can remove it.'**
  String get localProgress;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get effects;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get haptics;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacy;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @deleteData.
  ///
  /// In en, this message translates to:
  /// **'Data deletion instructions'**
  String get deleteData;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @savePending.
  ///
  /// In en, this message translates to:
  /// **'Saving progress…'**
  String get savePending;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Progress could not be saved. Retry before closing the game.'**
  String get saveFailed;

  /// No description provided for @saveUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Saved progress could not be read. The original save is preserved. You can restore a backup in Settings.'**
  String get saveUnreadable;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Playing offline'**
  String get offline;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get retrySync;

  /// No description provided for @platformTrophies.
  ///
  /// In en, this message translates to:
  /// **'Online achievements'**
  String get platformTrophies;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice controls'**
  String get practice;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceTitle;

  /// No description provided for @practiceHold.
  ///
  /// In en, this message translates to:
  /// **'Hold anywhere'**
  String get practiceHold;

  /// No description provided for @practiceRelease.
  ///
  /// In en, this message translates to:
  /// **'Now let go'**
  String get practiceRelease;

  /// No description provided for @practiceDone.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready'**
  String get practiceDone;

  /// No description provided for @startPlaying.
  ///
  /// In en, this message translates to:
  /// **'Start playing'**
  String get startPlaying;

  /// No description provided for @hardcoreIntro.
  ///
  /// In en, this message translates to:
  /// **'One hit ends the run.'**
  String get hardcoreIntro;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'This action is unavailable on this device.'**
  String get notAvailable;

  /// No description provided for @signInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google Play Games sign-in did not complete. You can keep playing offline.'**
  String get signInCancelled;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this action. Please try again.'**
  String get actionFailed;

  /// No description provided for @textFailed.
  ///
  /// In en, this message translates to:
  /// **'Game text could not be prepared.'**
  String get textFailed;

  /// No description provided for @returnMenu.
  ///
  /// In en, this message translates to:
  /// **'Return to menu'**
  String get returnMenu;

  /// No description provided for @hangar.
  ///
  /// In en, this message translates to:
  /// **'Hangar'**
  String get hangar;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// No description provided for @fieldGuide.
  ///
  /// In en, this message translates to:
  /// **'About Stars'**
  String get fieldGuide;

  /// No description provided for @fieldGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'FIELD GUIDE'**
  String get fieldGuideTitle;

  /// No description provided for @fluxTagline.
  ///
  /// In en, this message translates to:
  /// **'A good orbit pays off.'**
  String get fluxTagline;

  /// No description provided for @backHangar.
  ///
  /// In en, this message translates to:
  /// **'BACK TO HANGAR'**
  String get backHangar;

  /// No description provided for @fluxEarnTitle.
  ///
  /// In en, this message translates to:
  /// **'1 pickup = 1 Star'**
  String get fluxEarnTitle;

  /// No description provided for @fluxEarnHelp.
  ///
  /// In en, this message translates to:
  /// **'Collect in either mode. Your Stars are saved as you play.'**
  String get fluxEarnHelp;

  /// No description provided for @fluxSpendTitle.
  ///
  /// In en, this message translates to:
  /// **'New world. Same challenge.'**
  String get fluxSpendTitle;

  /// No description provided for @fluxSpendHelp.
  ///
  /// In en, this message translates to:
  /// **'Spend Stars on worlds in the hangar. Every world keeps the same rules.'**
  String get fluxSpendHelp;

  /// No description provided for @fluxSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Yours to keep'**
  String get fluxSaveTitle;

  /// No description provided for @fluxSaveHelp.
  ///
  /// In en, this message translates to:
  /// **'Start with 100 Stars. Your balance and worlds are saved on this device; uninstalling or clearing app data can remove them.'**
  String get fluxSaveHelp;

  /// No description provided for @equipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get equipped;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get owned;

  /// No description provided for @useWorld.
  ///
  /// In en, this message translates to:
  /// **'Use world'**
  String get useWorld;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @collectMore.
  ///
  /// In en, this message translates to:
  /// **'Collect more Stars to unlock this world.'**
  String get collectMore;

  /// No description provided for @walletFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this change. Your Stars have not been spent. Please retry.'**
  String get walletFailed;

  /// No description provided for @fluxFailed.
  ///
  /// In en, this message translates to:
  /// **'Stars could not be saved. Please retry before closing the game.'**
  String get fluxFailed;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @previousWorld.
  ///
  /// In en, this message translates to:
  /// **'Previous world'**
  String get previousWorld;

  /// No description provided for @nextWorld.
  ///
  /// In en, this message translates to:
  /// **'Next world'**
  String get nextWorld;

  /// No description provided for @bestLabel.
  ///
  /// In en, this message translates to:
  /// **'BEST  {score}'**
  String bestLabel(int score);

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String scoreLabel(int score);

  /// No description provided for @worldShopBalance.
  ///
  /// In en, this message translates to:
  /// **'World shop · {balance} Stars'**
  String worldShopBalance(int balance);

  /// No description provided for @earnedFlux.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{+1 Star saved} other{+{amount} Stars saved}}'**
  String earnedFlux(int amount);

  /// No description provided for @pendingFlux.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{+1 Star · save pending} other{+{amount} Stars · save pending}}'**
  String pendingFlux(int amount);

  /// No description provided for @progressCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target}'**
  String progressCount(int current, int target);

  /// No description provided for @unlockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} unlocked'**
  String unlockedCount(int count, int total);

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} updates waiting to sync'**
  String syncPending(int count);

  /// No description provided for @unlockPrice.
  ///
  /// In en, this message translates to:
  /// **'Unlock · {price} Stars'**
  String unlockPrice(int price);

  /// No description provided for @moreFlux.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{1 more Star to unlock} other{{amount} more Stars to unlock}}'**
  String moreFlux(int amount);

  /// No description provided for @oneTimePrice.
  ///
  /// In en, this message translates to:
  /// **'{price} Stars · one-time unlock'**
  String oneTimePrice(int price);

  /// No description provided for @fluxBalance.
  ///
  /// In en, this message translates to:
  /// **'{balance, plural, =1{1 Star} other{{balance} Stars}}'**
  String fluxBalance(int balance);

  /// No description provided for @fluxProgress.
  ///
  /// In en, this message translates to:
  /// **'{balance} of {price} Stars'**
  String fluxProgress(int balance, int price);

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String hoursMinutes(int hours, int minutes);

  /// No description provided for @achievementEarned.
  ///
  /// In en, this message translates to:
  /// **'Achievement: {title}'**
  String achievementEarned(String title);

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'{score, plural, one{I got 1 point in Atomic Orbital. Can you do better?} other{I got {score} points in Atomic Orbital. Can you do better?}}'**
  String shareMessage(int score);

  /// No description provided for @achievementTitle.
  ///
  /// In en, this message translates to:
  /// **'{id, select, normal20{20 Points Normal} normal35{35 Points Normal} normal50{50 Points Normal} hardcore20{20 Points Hardcore} hardcore35{35 Points Hardcore} hardcore50{50 Points Hardcore} points500{Total of 500 Points} points1000{Total of 1000 Points} points10000{Total of 10000 Points} games50{50 Games} games150{150 Games} games500{500 Games} firstContact{First Contact} findingOrbit{Finding Orbit} hardcoreCadet{Hardcore Cadet} steadyHands{Steady Hands} newHorizons{New Horizons} worldTour{World Tour} other{Achievement}}'**
  String achievementTitle(String id);

  /// No description provided for @achievementDescription.
  ///
  /// In en, this message translates to:
  /// **'{id, select, normal20{Reach 20 points in a completed Normal run.} normal35{Reach 35 points in a completed Normal run.} normal50{Reach 50 points in a completed Normal run.} hardcore20{Reach 20 points in a completed Hardcore run.} hardcore35{Reach 35 points in a completed Hardcore run.} hardcore50{Reach 50 points in a completed Hardcore run.} points500{Collect 500 points across completed runs.} points1000{Collect 1000 points across completed runs.} points10000{Collect 10000 points across completed runs.} games50{Complete 50 runs.} games150{Complete 150 runs.} games500{Complete 500 runs.} firstContact{Collect your first pickup in a real run.} findingOrbit{Reach 5 points in Normal.} hardcoreCadet{Reach 5 points in Hardcore.} steadyHands{Reach 10 Normal points before taking any hit.} newHorizons{Unlock your first themed world.} worldTour{Reach 5 points in Classic, Cow Abduction and Deep Blue.} other{Achievement}}'**
  String achievementDescription(String id);

  /// No description provided for @worldName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, classic{Classic} cow_abduction{Cow Abduction} deep_blue{Deep Blue} spider_web{Web Escape} dragon_hoard{Dragon’s Hoard} sunflower{Pollen Patrol} frost_bite{Frost Bite} haunted_harvest{Haunted Harvest} junkyard_dash{Junkyard Dash} volcano_hop{Volcano Hop} cheese_chase{Cheese Chase} jungle_jam{Jungle Jam} other{World}}'**
  String worldName(String id);

  /// No description provided for @worldDescription.
  ///
  /// In en, this message translates to:
  /// **'{id, select, classic{The original atomic arena.} cow_abduction{Fly the MOO-1. Beam up cows. Dodge Earth’s defenses.} deep_blue{Pilot the Bathyscout. Collect treasure chests. Dodge the kraken’s ink.} spider_web{Be a tiny fly. Snatch sugar cubes. Slip past the spider’s webs.} dragon_hoard{Guard your little knight. Gather gems. Dodge dragon fire.} sunflower{Fly a busy bee. Gather pollen. Dodge the sunflower’s seeds.} frost_bite{Guide a penguin. Catch fish. Dodge the snow monster’s ice.} haunted_harvest{Float a little ghost. Collect candy. Dodge the pumpkin’s bats.} junkyard_dash{Pilot a repair drone. Collect bolts. Dodge the robot’s sparks.} volcano_hop{Fly a pterosaur. Rescue eggs. Dodge flying lava.} cheese_chase{Scurry as a mouse. Snatch cheese. Dodge the cat’s yarn.} jungle_jam{Fly a toucan. Gather bananas. Dodge the monkey’s coconuts.} other{Choose your next world.}}'**
  String worldDescription(String id);

  /// No description provided for @walletUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Wallet unavailable'**
  String get walletUnavailable;

  /// No description provided for @equippedReady.
  ///
  /// In en, this message translates to:
  /// **'Equipped · ready for launch'**
  String get equippedReady;

  /// No description provided for @worldReady.
  ///
  /// In en, this message translates to:
  /// **'World unlocked · ready to equip'**
  String get worldReady;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get you;

  /// No description provided for @holdToStart.
  ///
  /// In en, this message translates to:
  /// **'HOLD TO START'**
  String get holdToStart;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'HEALTH'**
  String get health;

  /// No description provided for @oneHitLabel.
  ///
  /// In en, this message translates to:
  /// **'ONE HIT'**
  String get oneHitLabel;

  /// No description provided for @profileChanged.
  ///
  /// In en, this message translates to:
  /// **'Your game-service profile changed. Updates are kept for the original profile; switch back to sync them.'**
  String get profileChanged;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync could not complete. Your local records are kept.'**
  String get syncFailed;

  /// No description provided for @rangeWarning.
  ///
  /// In en, this message translates to:
  /// **'The published leaderboard cannot accept this score. Your local record is saved.'**
  String get rangeWarning;

  /// No description provided for @nativeSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in did not complete. You can keep playing offline.'**
  String get nativeSignInCancelled;

  /// No description provided for @disconnectService.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {service}'**
  String disconnectService(String service);

  /// No description provided for @endRunHelp.
  ///
  /// In en, this message translates to:
  /// **'Leaving now keeps achievements earned during play. Records and run statistics update at Game Over.'**
  String get endRunHelp;

  /// No description provided for @practiceHoldHelp.
  ///
  /// In en, this message translates to:
  /// **'Move the white dot out. Keep holding until it reaches the square.'**
  String get practiceHoldHelp;

  /// No description provided for @practiceReleaseHelp.
  ///
  /// In en, this message translates to:
  /// **'Each square reverses your direction. Let go to move in and collect the next one.'**
  String get practiceReleaseHelp;

  /// No description provided for @practiceDoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Hold to move out. Release to move in.\nSquares reverse your direction. Avoid the red dots.'**
  String get practiceDoneHelp;

  /// No description provided for @practiceTouchHint.
  ///
  /// In en, this message translates to:
  /// **'Touch anywhere to begin'**
  String get practiceTouchHint;

  /// No description provided for @practiceHolding.
  ///
  /// In en, this message translates to:
  /// **'Holding · moving out'**
  String get practiceHolding;

  /// No description provided for @practiceReleased.
  ///
  /// In en, this message translates to:
  /// **'Released · moving in'**
  String get practiceReleased;

  /// No description provided for @practiceAnywhereHelp.
  ///
  /// In en, this message translates to:
  /// **'You don\'t need to tap the dot or the square.'**
  String get practiceAnywhereHelp;

  /// No description provided for @practiceDoneFeedback.
  ///
  /// In en, this message translates to:
  /// **'Both squares collected'**
  String get practiceDoneFeedback;

  /// No description provided for @progressLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device.'**
  String get progressLocalNote;

  /// No description provided for @newBestAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New personal best: {score}'**
  String newBestAnnouncement(int score);

  /// No description provided for @personalBestAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Personal best: {score}'**
  String personalBestAnnouncement(int score);

  /// No description provided for @newDailyBestAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New daily best: {score}'**
  String newDailyBestAnnouncement(int score);

  /// No description provided for @dailyBestAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Daily best: {score}'**
  String dailyBestAnnouncement(int score);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveBackup.
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get saveBackup;

  /// No description provided for @exportSave.
  ///
  /// In en, this message translates to:
  /// **'Export save'**
  String get exportSave;

  /// No description provided for @importSave.
  ///
  /// In en, this message translates to:
  /// **'Import save'**
  String get importSave;

  /// No description provided for @restorePreviousSave.
  ///
  /// In en, this message translates to:
  /// **'Restore previous save'**
  String get restorePreviousSave;

  /// No description provided for @backupExplanation.
  ///
  /// In en, this message translates to:
  /// **'Save a file you can restore on another device. Online profiles and pending uploads are not included.'**
  String get backupExplanation;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Save exported.'**
  String get backupExported;

  /// No description provided for @backupImported.
  ///
  /// In en, this message translates to:
  /// **'Save restored.'**
  String get backupImported;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup action failed. Your current save has been kept.'**
  String get backupFailed;

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file is not a supported Atomic Orbital save.'**
  String get backupInvalid;

  /// No description provided for @backupPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this save?'**
  String get backupPreviewTitle;

  /// No description provided for @backupReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'This replaces your progress and settings. You can restore the previous save afterward.'**
  String get backupReplaceWarning;

  /// No description provided for @backupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace save'**
  String get backupConfirm;

  /// No description provided for @backupCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current save'**
  String get backupCurrent;

  /// No description provided for @backupIncoming.
  ///
  /// In en, this message translates to:
  /// **'Selected save'**
  String get backupIncoming;

  /// No description provided for @backupStoredItems.
  ///
  /// In en, this message translates to:
  /// **'Stored worlds'**
  String get backupStoredItems;

  /// No description provided for @backupStars.
  ///
  /// In en, this message translates to:
  /// **'Stored Stars'**
  String get backupStars;

  /// No description provided for @backupRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'A save replacement could not be recovered. Your saved copies are preserved. Restart the app before making more changes.'**
  String get backupRecoveryFailed;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get dailyChallenge;

  /// No description provided for @dailyIntro.
  ///
  /// In en, this message translates to:
  /// **'A new Normal challenge every day. Replay today’s challenge as often as you like. Your daily best stays separate from your other records.'**
  String get dailyIntro;

  /// No description provided for @dailyReset.
  ///
  /// In en, this message translates to:
  /// **'Next challenge: {time} (local time)'**
  String dailyReset(String time);

  /// No description provided for @dailyDate.
  ///
  /// In en, this message translates to:
  /// **'{date} · UTC'**
  String dailyDate(String date);

  /// No description provided for @dailyBest.
  ///
  /// In en, this message translates to:
  /// **'Daily best'**
  String get dailyBest;

  /// No description provided for @dailyLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. The challenge date comes from your device clock.'**
  String get dailyLocalNote;

  /// No description provided for @dailySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The daily result could not be saved. Retry before closing the game.'**
  String get dailySaveFailed;

  /// No description provided for @runDuration.
  ///
  /// In en, this message translates to:
  /// **'Time: {duration}'**
  String runDuration(String duration);

  /// No description provided for @dailyShareMessage.
  ///
  /// In en, this message translates to:
  /// **'I scored {score} in Atomic Orbital’s daily challenge for {date} (UTC).'**
  String dailyShareMessage(int score, String date);

  /// No description provided for @worldCollection.
  ///
  /// In en, this message translates to:
  /// **'World collection'**
  String get worldCollection;

  /// No description provided for @collectionProgress.
  ///
  /// In en, this message translates to:
  /// **'{owned} of {total} unlocked'**
  String collectionProgress(int owned, int total);

  /// No description provided for @dailyUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Saved daily results could not be read. The original save is preserved. Restore a backup in Settings.'**
  String get dailyUnreadable;

  /// No description provided for @dailyEndRunHelp.
  ///
  /// In en, this message translates to:
  /// **'Leaving now will not save a daily result. Finish the run to record it.'**
  String get dailyEndRunHelp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
