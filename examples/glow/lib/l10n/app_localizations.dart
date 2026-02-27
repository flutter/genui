import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get appTitle;

  /// Subtitle on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Personalized Wallpaper & GenUI Showcase'**
  String get welcomeSubtitle;

  /// Description on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Glow! Take a fun, interactive personality quiz driven by Gemini AI to discover your unique visual style. We\'ll generate a one-of-a-kind phone wallpaper, and then you can refine it through an iterative, agent-assisted creative process.'**
  String get welcomeDescription;

  /// Label for personality quiz feature
  ///
  /// In en, this message translates to:
  /// **'Personality Quiz'**
  String get personalityQuiz;

  /// Label for AI generation feature
  ///
  /// In en, this message translates to:
  /// **'AI Generation'**
  String get aiGeneration;

  /// Label for iterative refinement feature
  ///
  /// In en, this message translates to:
  /// **'Iterative Refinement'**
  String get iterativeRefinement;

  /// Button text to get started
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Button text to change API key
  ///
  /// In en, this message translates to:
  /// **'Change API Key'**
  String get changeApiKey;

  /// Footer text showing technology stack
  ///
  /// In en, this message translates to:
  /// **'Powered by GenUI SDK for Flutter & Gemini Models'**
  String get poweredBy;

  /// Title of the API key dialog
  ///
  /// In en, this message translates to:
  /// **'Enter Gemini API Key'**
  String get apiKeyDialogTitle;

  /// Description in the API key dialog
  ///
  /// In en, this message translates to:
  /// **'To use Glow, you need a free Gemini API Key.'**
  String get apiKeyDialogDescription;

  /// Link text to get an API key
  ///
  /// In en, this message translates to:
  /// **'Get an API Key here'**
  String get getApiKeyHere;

  /// Label for API key input field
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Title of the quiz screen
  ///
  /// In en, this message translates to:
  /// **'Glow Personality Quiz'**
  String get quizTitle;

  /// Counter for the current question
  ///
  /// In en, this message translates to:
  /// **'Question {currentIndex} of {totalQuestions}'**
  String questionCount(int currentIndex, int totalQuestions);

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Skip to generation button text
  ///
  /// In en, this message translates to:
  /// **'Skip to generation'**
  String get skipToGeneration;

  /// Text shown during wallpaper generation
  ///
  /// In en, this message translates to:
  /// **'Generating your personal glow...'**
  String get generatingGlow;

  /// Description shown during wallpaper generation
  ///
  /// In en, this message translates to:
  /// **'Using Gemini to create your wallpaper.\nThis may take a moment.'**
  String get generationDescription;

  /// Header for adjusting wallpaper settings
  ///
  /// In en, this message translates to:
  /// **'Adjust Wallpaper'**
  String get adjustWallpaper;

  /// Header for wallpaper style selection
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Style'**
  String get wallpaperStyle;

  /// Label for the regenerate button
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// Label for the Cosmic style
  ///
  /// In en, this message translates to:
  /// **'Cosmic'**
  String get styleCosmic;

  /// Label for the Abstract style
  ///
  /// In en, this message translates to:
  /// **'Abstract'**
  String get styleAbstract;

  /// Label for the Nature style
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get styleNature;

  /// Label for the Crystal style
  ///
  /// In en, this message translates to:
  /// **'Crystal'**
  String get styleCrystal;

  /// Label for the warm and calm atmosphere setting
  ///
  /// In en, this message translates to:
  /// **'Warm & Calm'**
  String get atmosphereWarmCalm;

  /// Label for the cool and energetic atmosphere setting
  ///
  /// In en, this message translates to:
  /// **'Cool & Energetic'**
  String get atmosphereCoolEnergetic;

  /// Label for the atmosphere slider
  ///
  /// In en, this message translates to:
  /// **'Atmosphere'**
  String get atmosphereLabel;

  /// Label for the key element selection
  ///
  /// In en, this message translates to:
  /// **'Key Element'**
  String get keyElementLabel;

  /// Default title for the wallpaper editor
  ///
  /// In en, this message translates to:
  /// **'My Glow Wallpaper'**
  String get myGlowWallpaper;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
