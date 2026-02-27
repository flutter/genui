// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Glow';

  @override
  String get welcomeSubtitle => 'Personalized Wallpaper & GenUI Showcase';

  @override
  String get welcomeDescription =>
      'Welcome to Glow! Take a fun, interactive personality quiz driven by Gemini AI to discover your unique visual style. We\'ll generate a one-of-a-kind phone wallpaper, and then you can refine it through an iterative, agent-assisted creative process.';

  @override
  String get personalityQuiz => 'Personality Quiz';

  @override
  String get aiGeneration => 'AI Generation';

  @override
  String get iterativeRefinement => 'Iterative Refinement';

  @override
  String get getStarted => 'Get Started';

  @override
  String get changeApiKey => 'Change API Key';

  @override
  String get poweredBy => 'Powered by GenUI SDK for Flutter & Gemini Models';

  @override
  String get apiKeyDialogTitle => 'Enter Gemini API Key';

  @override
  String get apiKeyDialogDescription =>
      'To use Glow, you need a free Gemini API Key.';

  @override
  String get getApiKeyHere => 'Get an API Key here';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get quizTitle => 'Glow Personality Quiz';

  @override
  String questionCount(int currentIndex, int totalQuestions) {
    return 'Question $currentIndex of $totalQuestions';
  }

  @override
  String get next => 'Next';

  @override
  String get skipToGeneration => 'Skip to generation';

  @override
  String get generatingGlow => 'Generating your personal glow...';

  @override
  String get generationDescription =>
      'Using Gemini to create your wallpaper.\nThis may take a moment.';

  @override
  String get adjustWallpaper => 'Adjust Wallpaper';

  @override
  String get wallpaperStyle => 'Wallpaper Style';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get styleCosmic => 'Cosmic';

  @override
  String get styleAbstract => 'Abstract';

  @override
  String get styleNature => 'Nature';

  @override
  String get styleCrystal => 'Crystal';

  @override
  String get atmosphereWarmCalm => 'Warm & Calm';

  @override
  String get atmosphereCoolEnergetic => 'Cool & Energetic';

  @override
  String get atmosphereLabel => 'Atmosphere';

  @override
  String get keyElementLabel => 'Key Element';

  @override
  String get myGlowWallpaper => 'My Glow Wallpaper';
}
