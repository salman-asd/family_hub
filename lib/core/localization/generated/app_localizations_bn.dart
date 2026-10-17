// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'ফ্যামিলি হাব';

  @override
  String get navHome => 'হোম';

  @override
  String get navChores => 'কাজ';

  @override
  String get navBazar => 'বাজার';

  @override
  String get navFamily => 'পরিবার';

  @override
  String get actionSave => 'সংরক্ষণ';

  @override
  String get actionCancel => 'বাতিল';

  @override
  String get actionRetry => 'আবার চেষ্টা করুন';

  @override
  String get actionDelete => 'মুছুন';

  @override
  String get actionEdit => 'সম্পাদনা';

  @override
  String get actionClose => 'বন্ধ করুন';

  @override
  String get actionBack => 'ফিরে যান';

  @override
  String get actionContinue => 'চালিয়ে যান';

  @override
  String get actionDone => 'সম্পন্ন';

  @override
  String get authSignInTitle => 'লগ ইন করুন';

  @override
  String get authSignUpTitle => 'নতুন অ্যাকাউন্ট খুলুন';

  @override
  String get authEmailLabel => 'ইমেইল';

  @override
  String get authPasswordLabel => 'পাসওয়ার্ড';

  @override
  String get authForgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get authSignOut => 'লগ আউট';

  @override
  String get authEmailVerificationSent => 'যাচাইকরণ ইমেইল পাঠানো হয়েছে।';

  @override
  String get authWelcomeHeadline => 'পরিবারের হিসাব, এক জায়গায়';

  @override
  String get authWelcomeMessage =>
      'বাজার খরচ, পরিবারের তহবিল আর কাজের রুটিন — সবাই মিলে একসাথে সামলান।';

  @override
  String get authGetStarted => 'শুরু করুন';

  @override
  String get authSignInAction => 'লগ ইন';

  @override
  String get authCreateAccountAction => 'নতুন অ্যাকাউন্ট খুলুন';

  @override
  String get authSignInSubtitle =>
      'আপনার ইমেইল ও পাসওয়ার্ড দিয়ে প্রবেশ করুন।';

  @override
  String get authSignUpSubtitle =>
      'অ্যাকাউন্ট খুললে একটি যাচাইকরণ ইমেইল পাঠানো হবে।';

  @override
  String get authNoAccountYet => 'অ্যাকাউন্ট নেই?';

  @override
  String get authAlreadyHaveAccount => 'আগেই অ্যাকাউন্ট আছে?';

  @override
  String get authShowPassword => 'পাসওয়ার্ড দেখান';

  @override
  String get authHidePassword => 'পাসওয়ার্ড লুকান';

  @override
  String get authEmailHint => 'যেমন name@example.com';

  @override
  String get authPasswordHint => 'অন্তত ৮ অক্ষর';

  @override
  String get authEmailConfirmed => 'ইমেইল';

  @override
  String get authPasswordTooShortHelper => 'কমপক্ষে ৮ অক্ষরের পাসওয়ার্ড দিন।';

  @override
  String get authPasswordConfirmLabel => 'পাসওয়ার্ড আবার লিখুন';

  @override
  String get authFailureValidationPasswordMismatch =>
      'দুটি পাসওয়ার্ড মিলছে না।';

  @override
  String get authFailureValidationPasswordConfirmRequired =>
      'পাসওয়ার্ডটি আবার লিখুন।';

  @override
  String get authForgotPasswordTitle => 'পাসওয়ার্ড রিসেট';

  @override
  String get authForgotPasswordSubtitle =>
      'ইমেইল দিন, আমরা একটি রিসেট লিংক পাঠাব।';

  @override
  String get authForgotPasswordSend => 'রিসেট লিংক পাঠান';

  @override
  String get authForgotPasswordSentTitle => 'ইমেইল পাঠানো হয়েছে';

  @override
  String authForgotPasswordSentMessage(String email) {
    return '$email ঠিকানায় একটি রিসেট লিংক পাঠানো হয়েছে। স্প্যাম ফোল্ডারও দেখে নিন।';
  }

  @override
  String get authVerifyEmailTitle => 'ইমেইল যাচাই করুন';

  @override
  String authVerifyEmailMessage(String email) {
    return '$email ঠিকানায় একটি যাচাইকরণ লিংক পাঠানো হয়েছে। লিংকে চাপ দিয়ে তারপর নিচের বাটনে চাপ দিন।';
  }

  @override
  String get authVerifyEmailIHaveVerified => 'আমি যাচাই করেছি';

  @override
  String get authVerifyEmailResend => 'আবার ইমেইল পাঠান';

  @override
  String get authVerifyEmailStillUnverified =>
      'এখনো যাচাই হয়নি। ইমেইলের লিংকে চাপ দিন, তারপর আবার চেষ্টা করুন।';

  @override
  String get authVerifyEmailVerified => 'ইমেইল যাচাই সম্পন্ন হয়েছে।';

  @override
  String get authVerifyEmailSignOutInstead => 'অন্য অ্যাকাউন্টে ঢুকুন';

  @override
  String authUsingAccount(String email) {
    return 'লগ ইন করা আছে: $email';
  }

  @override
  String get authFailurePermissionDenied => 'আপনার এই কাজটি করার অনুমতি নেই।';

  @override
  String get authFailureNotFound => 'আপনার অ্যাকাউন্টটি খুঁজে পাওয়া যায়নি।';

  @override
  String get authFailureConflict =>
      'কেউ ইতিমধ্যে তথ্য বদলেছে। অ্যাপটি আবার খুলে চেষ্টা করুন।';

  @override
  String get authFailureNetwork =>
      'ইন্টারনেট সংযোগ পাওয়া যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get authFailureInvalidCredentials => 'ইমেইল বা পাসওয়ার্ড ঠিক নয়।';

  @override
  String get authFailureUserNotFound => 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই।';

  @override
  String get authFailureEmailInUse =>
      'এই ইমেইলে আগেই একটি অ্যাকাউন্ট আছে। লগ ইন করে দেখুন।';

  @override
  String get authFailureWeakPassword =>
      'পাসওয়ার্ডটি দুর্বল। অন্তত ৮ অক্ষরের পাসওয়ার্ড দিন।';

  @override
  String get authFailureTooManyRequests =>
      'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।';

  @override
  String get authFailureUserDisabled =>
      'এই অ্যাকাউন্টটি বন্ধ করা হয়েছে। পরিবারের অ্যাডমিনের সাথে কথা বলুন।';

  @override
  String get authFailureRequiresRecentLogin =>
      'নিরাপত্তার জন্য আবার লগ ইন করুন, তারপর চেষ্টা করুন।';

  @override
  String get authFailureInvalidEmail => 'ইমেইল ঠিকানাটি সঠিক নয়।';

  @override
  String get authFailureNoCurrentUser =>
      'আপনি আগে লগ আউট করেছেন। আবার লগ ইন করুন।';

  @override
  String authFailureValidationRequired(String field) {
    return '$field পূরণ করুন।';
  }

  @override
  String get authFailureValidationInvalidEmail => 'সঠিক ইমেইল ঠিকানা দিন।';

  @override
  String get authFailureValidationPasswordTooShort =>
      'পাসওয়ার্ড অন্তত ৮ অক্ষরের হতে হবে।';

  @override
  String get authFailureUnknown => 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get authFieldEmail => 'ইমেইল';

  @override
  String get authFieldPassword => 'পাসওয়ার্ড';

  @override
  String get errorPermissionDenied => 'আপনার এই কাজটি করার অনুমতি নেই।';

  @override
  String get errorNotFound => 'তথ্যটি খুঁজে পাওয়া যায়নি।';

  @override
  String get errorConflict =>
      'কেউ ইতিমধ্যে এই তথ্য পরিবর্তন করেছে। আবার চেষ্টা করুন।';

  @override
  String get errorNetwork =>
      'ইন্টারনেট সংযোগ পাওয়া যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get errorUnknown => 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String errorValidationRequired(String field) {
    return '$field পূরণ করুন।';
  }

  @override
  String get errorValidationEmail => 'সঠিক ইমেইল ঠিকানা দিন।';

  @override
  String get errorValidationPasswordTooShort =>
      'পাসওয়ার্ড অন্তত ৮ অক্ষরের হতে হবে।';

  @override
  String get emptyGenericTitle => 'এখনো কিছু নেই';

  @override
  String get emptyGenericMessage => 'শুরু করতে নিচের বাটনে চাপ দিন।';

  @override
  String get emptyNoDataTitle => 'কোনো তথ্য নেই';

  @override
  String get emptyNoDataMessage => 'এই তালিকাটি এখন খালি।';

  @override
  String get loadingGeneric => 'লোড হচ্ছে…';

  @override
  String get offlineBanner => 'আপনি অফলাইনে আছেন। সংযোগ ফিরলে তথ্য সিঙ্ক হবে।';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsThemeTitle => 'অ্যাপিয়ারেন্স';

  @override
  String get settingsThemeMode => 'থিম মোড';

  @override
  String get settingsColourPalette => 'রঙের প্যালেট';

  @override
  String get settingsFollowDevice => 'ডিভাইস অনুসরণ করুন';

  @override
  String get settingsFollowDeviceSubtitle =>
      'আপনার সিস্টেমের আলো / অন্ধকার সেটিং ব্যবহার করবে';

  @override
  String get settingsThemeSelected => 'নির্বাচিত';

  @override
  String settingsThemeSelectedSemantics(String theme) {
    return '$theme থিম, নির্বাচিত';
  }

  @override
  String settingsThemeUnselectedSemantics(String theme) {
    return '$theme থিম';
  }

  @override
  String get settingsLanguageTitle => 'ভাষা';

  @override
  String get settingsLanguageSection => 'ভাষা নির্বাচন করুন';

  @override
  String get settingsLanguageBangla => 'বাংলা';

  @override
  String get settingsLanguageEnglish => 'ইংরেজি';

  @override
  String get settingsLanguageSubtitle =>
      'অ্যাপের ভাষা তাৎক্ষণিকভাবে পরিবর্তিত হয়';

  @override
  String get settingsBanglaDigits => 'বাংলা অঙ্ক ব্যবহার করুন';

  @override
  String get settingsBanglaDigitsSubtitle =>
      'সংখ্যা ও তারিখ বাংলা অঙ্কে (০১২৩) দেখাবে';

  @override
  String settingsLanguageSelectedSemantics(String language) {
    return '$language ভাষা, নির্বাচিত';
  }

  @override
  String get languageNameBn => 'বাংলা';

  @override
  String get languageNameEn => 'English';

  @override
  String get devTokensTitle => 'ডেভ — থিম টোকেন';

  @override
  String get devGalleryTitle => 'ডেভ — গ্যালারি';

  @override
  String get homeViewThemeTokens => 'থিম টোকেন দেখুন';
}
