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
  String get authSignInTitle => 'লগ ইন';

  @override
  String get authSignUpTitle => 'নতুন অ্যাকাউন্ট';

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
