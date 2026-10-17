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
  String get authWelcomeHeadline => 'Your family\'s money, in one place';

  @override
  String get authWelcomeMessage =>
      'Bazar spending, the family fund and the chore rota — managed together.';

  @override
  String get authGetStarted => 'Get started';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authCreateAccountAction => 'Create an account';

  @override
  String get authSignInSubtitle => 'Enter with your email and password.';

  @override
  String get authSignUpSubtitle =>
      'We will send a verification email when you sign up.';

  @override
  String get authNoAccountYet => 'No account yet?';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authEmailHint => 'e.g. name@example.com';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String get authEmailConfirmed => 'Email';

  @override
  String get authPasswordTooShortHelper => 'Use at least 8 characters.';

  @override
  String get authPasswordConfirmLabel => 'Repeat password';

  @override
  String get authFailureValidationPasswordMismatch =>
      'The two passwords do not match.';

  @override
  String get authFailureValidationPasswordConfirmRequired =>
      'Please repeat the password.';

  @override
  String get authForgotPasswordTitle => 'Reset password';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your email and we will send a reset link.';

  @override
  String get authForgotPasswordSend => 'Send reset link';

  @override
  String get authForgotPasswordSentTitle => 'Email sent';

  @override
  String authForgotPasswordSentMessage(String email) {
    return 'A reset link was sent to $email. Check your spam folder too.';
  }

  @override
  String get authVerifyEmailTitle => 'Verify your email';

  @override
  String authVerifyEmailMessage(String email) {
    return 'We sent a verification link to $email. Tap the link, then press the button below.';
  }

  @override
  String get authVerifyEmailIHaveVerified => 'I have verified';

  @override
  String get authVerifyEmailResend => 'Send the email again';

  @override
  String get authVerifyEmailStillUnverified =>
      'Not verified yet. Tap the link in the email, then try again.';

  @override
  String get authVerifyEmailVerified => 'Your email is verified.';

  @override
  String get authVerifyEmailSignOutInstead => 'Use a different account';

  @override
  String authUsingAccount(String email) {
    return 'Signed in as $email';
  }

  @override
  String get authFailurePermissionDenied =>
      'You do not have permission to do this.';

  @override
  String get authFailureNotFound => 'Your account could not be found.';

  @override
  String get authFailureConflict =>
      'Someone already changed this. Reopen the app and try again.';

  @override
  String get authFailureNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get authFailureInvalidCredentials =>
      'That email or password is not correct.';

  @override
  String get authFailureUserNotFound => 'There is no account for this email.';

  @override
  String get authFailureEmailInUse =>
      'An account already uses this email. Try signing in.';

  @override
  String get authFailureWeakPassword =>
      'That password is too weak. Use at least 8 characters.';

  @override
  String get authFailureTooManyRequests =>
      'Too many attempts. Please try again in a little while.';

  @override
  String get authFailureUserDisabled =>
      'This account is disabled. Talk to your family admin.';

  @override
  String get authFailureRequiresRecentLogin =>
      'For security, sign in again and then retry.';

  @override
  String get authFailureInvalidEmail => 'That email address is not valid.';

  @override
  String get authFailureNoCurrentUser =>
      'You were signed out. Please sign in again.';

  @override
  String authFailureValidationRequired(String field) {
    return 'Please fill in $field.';
  }

  @override
  String get authFailureValidationInvalidEmail =>
      'Enter a valid email address.';

  @override
  String get authFailureValidationPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String get authFailureUnknown => 'Something went wrong. Please try again.';

  @override
  String get authFieldEmail => 'email';

  @override
  String get authFieldPassword => 'password';

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
