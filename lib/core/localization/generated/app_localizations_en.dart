// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Family Hub';

  @override
  String get navHome => 'Home';

  @override
  String get navChores => 'Chores';

  @override
  String get navBazar => 'Bazar';

  @override
  String get navFamily => 'Family';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionClose => 'Close';

  @override
  String get actionBack => 'Back';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionDone => 'Done';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authEmailVerificationSent => 'Verification email sent.';

  @override
  String get errorPermissionDenied => 'You do not have permission to do this.';

  @override
  String get errorNotFound => 'That item could not be found.';

  @override
  String get errorConflict => 'Someone already changed this. Please try again.';

  @override
  String get errorNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String errorValidationRequired(String field) {
    return 'Please fill in $field.';
  }

  @override
  String get errorValidationEmail => 'Enter a valid email address.';

  @override
  String get errorValidationPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String get emptyGenericTitle => 'Nothing here yet';

  @override
  String get emptyGenericMessage => 'Tap the button below to get started.';

  @override
  String get emptyNoDataTitle => 'No data';

  @override
  String get emptyNoDataMessage => 'This list is empty right now.';

  @override
  String get loadingGeneric => 'Loading…';

  @override
  String get offlineBanner =>
      'You are offline. Data will sync when the connection returns.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsThemeTitle => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme mode';

  @override
  String get settingsColourPalette => 'Colour palette';

  @override
  String get settingsFollowDevice => 'Follow device';

  @override
  String get settingsFollowDeviceSubtitle =>
      'Uses your system light / dark setting';

  @override
  String get settingsThemeSelected => 'Selected';

  @override
  String settingsThemeSelectedSemantics(String theme) {
    return '$theme theme, selected';
  }

  @override
  String settingsThemeUnselectedSemantics(String theme) {
    return '$theme theme';
  }

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSection => 'Choose a language';

  @override
  String get settingsLanguageBangla => 'Bangla';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageSubtitle => 'The app language changes instantly';

  @override
  String get settingsBanglaDigits => 'Use Bangla digits';

  @override
  String get settingsBanglaDigitsSubtitle =>
      'Numbers and dates shown with Bangla digits (০১২৩)';

  @override
  String settingsLanguageSelectedSemantics(String language) {
    return '$language language, selected';
  }

  @override
  String get languageNameBn => 'বাংলা';

  @override
  String get languageNameEn => 'English';

  @override
  String get devTokensTitle => 'Dev — Theme Tokens';

  @override
  String get devGalleryTitle => 'Dev — Gallery';

  @override
  String get homeViewThemeTokens => 'View Theme Tokens';
}
