import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('bn'),
    Locale('en')
  ];

  /// The application name shown in the app bar and store listing.
  ///
  /// In bn, this message translates to:
  /// **'ফ্যামিলি হাব'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In bn, this message translates to:
  /// **'হোম'**
  String get navHome;

  /// No description provided for @navChores.
  ///
  /// In bn, this message translates to:
  /// **'কাজ'**
  String get navChores;

  /// No description provided for @navBazar.
  ///
  /// In bn, this message translates to:
  /// **'বাজার'**
  String get navBazar;

  /// No description provided for @navFamily.
  ///
  /// In bn, this message translates to:
  /// **'পরিবার'**
  String get navFamily;

  /// No description provided for @actionSave.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা করুন'**
  String get actionRetry;

  /// No description provided for @actionDelete.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In bn, this message translates to:
  /// **'সম্পাদনা'**
  String get actionEdit;

  /// No description provided for @actionClose.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করুন'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In bn, this message translates to:
  /// **'ফিরে যান'**
  String get actionBack;

  /// No description provided for @actionContinue.
  ///
  /// In bn, this message translates to:
  /// **'চালিয়ে যান'**
  String get actionContinue;

  /// No description provided for @actionDone.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন'**
  String get actionDone;

  /// No description provided for @authSignInTitle.
  ///
  /// In bn, this message translates to:
  /// **'লগ ইন করুন'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন অ্যাকাউন্ট খুলুন'**
  String get authSignUpTitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড'**
  String get authPasswordLabel;

  /// No description provided for @authForgotPassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড ভুলে গেছেন?'**
  String get authForgotPassword;

  /// No description provided for @authSignOut.
  ///
  /// In bn, this message translates to:
  /// **'লগ আউট'**
  String get authSignOut;

  /// No description provided for @authEmailVerificationSent.
  ///
  /// In bn, this message translates to:
  /// **'যাচাইকরণ ইমেইল পাঠানো হয়েছে।'**
  String get authEmailVerificationSent;

  /// Headline on the welcome screen.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারের হিসাব, এক জায়গায়'**
  String get authWelcomeHeadline;

  /// No description provided for @authWelcomeMessage.
  ///
  /// In bn, this message translates to:
  /// **'বাজার খরচ, পরিবারের তহবিল আর কাজের রুটিন — সবাই মিলে একসাথে সামলান।'**
  String get authWelcomeMessage;

  /// No description provided for @authGetStarted.
  ///
  /// In bn, this message translates to:
  /// **'শুরু করুন'**
  String get authGetStarted;

  /// No description provided for @authSignInAction.
  ///
  /// In bn, this message translates to:
  /// **'লগ ইন'**
  String get authSignInAction;

  /// No description provided for @authCreateAccountAction.
  ///
  /// In bn, this message translates to:
  /// **'নতুন অ্যাকাউন্ট খুলুন'**
  String get authCreateAccountAction;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার ইমেইল ও পাসওয়ার্ড দিয়ে প্রবেশ করুন।'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট খুললে একটি যাচাইকরণ ইমেইল পাঠানো হবে।'**
  String get authSignUpSubtitle;

  /// No description provided for @authNoAccountYet.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট নেই?'**
  String get authNoAccountYet;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In bn, this message translates to:
  /// **'আগেই অ্যাকাউন্ট আছে?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authShowPassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড দেখান'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড লুকান'**
  String get authHidePassword;

  /// No description provided for @authEmailHint.
  ///
  /// In bn, this message translates to:
  /// **'যেমন name@example.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In bn, this message translates to:
  /// **'অন্তত ৮ অক্ষর'**
  String get authPasswordHint;

  /// No description provided for @authEmailConfirmed.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get authEmailConfirmed;

  /// No description provided for @authPasswordTooShortHelper.
  ///
  /// In bn, this message translates to:
  /// **'কমপক্ষে ৮ অক্ষরের পাসওয়ার্ড দিন।'**
  String get authPasswordTooShortHelper;

  /// No description provided for @authPasswordConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড আবার লিখুন'**
  String get authPasswordConfirmLabel;

  /// No description provided for @authFailureValidationPasswordMismatch.
  ///
  /// In bn, this message translates to:
  /// **'দুটি পাসওয়ার্ড মিলছে না।'**
  String get authFailureValidationPasswordMismatch;

  /// No description provided for @authFailureValidationPasswordConfirmRequired.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ডটি আবার লিখুন।'**
  String get authFailureValidationPasswordConfirmRequired;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল দিন, আমরা একটি রিসেট লিংক পাঠাব।'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordSend.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট লিংক পাঠান'**
  String get authForgotPasswordSend;

  /// No description provided for @authForgotPasswordSentTitle.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল পাঠানো হয়েছে'**
  String get authForgotPasswordSentTitle;

  /// No description provided for @authForgotPasswordSentMessage.
  ///
  /// In bn, this message translates to:
  /// **'{email} ঠিকানায় একটি রিসেট লিংক পাঠানো হয়েছে। স্প্যাম ফোল্ডারও দেখে নিন।'**
  String authForgotPasswordSentMessage(String email);

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল যাচাই করুন'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailMessage.
  ///
  /// In bn, this message translates to:
  /// **'{email} ঠিকানায় একটি যাচাইকরণ লিংক পাঠানো হয়েছে। লিংকে চাপ দিয়ে তারপর নিচের বাটনে চাপ দিন।'**
  String authVerifyEmailMessage(String email);

  /// No description provided for @authVerifyEmailIHaveVerified.
  ///
  /// In bn, this message translates to:
  /// **'আমি যাচাই করেছি'**
  String get authVerifyEmailIHaveVerified;

  /// No description provided for @authVerifyEmailResend.
  ///
  /// In bn, this message translates to:
  /// **'আবার ইমেইল পাঠান'**
  String get authVerifyEmailResend;

  /// No description provided for @authVerifyEmailStillUnverified.
  ///
  /// In bn, this message translates to:
  /// **'এখনো যাচাই হয়নি। ইমেইলের লিংকে চাপ দিন, তারপর আবার চেষ্টা করুন।'**
  String get authVerifyEmailStillUnverified;

  /// No description provided for @authVerifyEmailVerified.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল যাচাই সম্পন্ন হয়েছে।'**
  String get authVerifyEmailVerified;

  /// No description provided for @authVerifyEmailSignOutInstead.
  ///
  /// In bn, this message translates to:
  /// **'অন্য অ্যাকাউন্টে ঢুকুন'**
  String get authVerifyEmailSignOutInstead;

  /// No description provided for @authUsingAccount.
  ///
  /// In bn, this message translates to:
  /// **'লগ ইন করা আছে: {email}'**
  String authUsingAccount(String email);

  /// No description provided for @authFailurePermissionDenied.
  ///
  /// In bn, this message translates to:
  /// **'আপনার এই কাজটি করার অনুমতি নেই।'**
  String get authFailurePermissionDenied;

  /// No description provided for @authFailureNotFound.
  ///
  /// In bn, this message translates to:
  /// **'আপনার অ্যাকাউন্টটি খুঁজে পাওয়া যায়নি।'**
  String get authFailureNotFound;

  /// No description provided for @authFailureConflict.
  ///
  /// In bn, this message translates to:
  /// **'কেউ ইতিমধ্যে তথ্য বদলেছে। অ্যাপটি আবার খুলে চেষ্টা করুন।'**
  String get authFailureConflict;

  /// No description provided for @authFailureNetwork.
  ///
  /// In bn, this message translates to:
  /// **'ইন্টারনেট সংযোগ পাওয়া যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।'**
  String get authFailureNetwork;

  /// No description provided for @authFailureInvalidCredentials.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল বা পাসওয়ার্ড ঠিক নয়।'**
  String get authFailureInvalidCredentials;

  /// No description provided for @authFailureUserNotFound.
  ///
  /// In bn, this message translates to:
  /// **'এই ইমেইলে কোনো অ্যাকাউন্ট নেই।'**
  String get authFailureUserNotFound;

  /// No description provided for @authFailureEmailInUse.
  ///
  /// In bn, this message translates to:
  /// **'এই ইমেইলে আগেই একটি অ্যাকাউন্ট আছে। লগ ইন করে দেখুন।'**
  String get authFailureEmailInUse;

  /// No description provided for @authFailureWeakPassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ডটি দুর্বল। অন্তত ৮ অক্ষরের পাসওয়ার্ড দিন।'**
  String get authFailureWeakPassword;

  /// No description provided for @authFailureTooManyRequests.
  ///
  /// In bn, this message translates to:
  /// **'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।'**
  String get authFailureTooManyRequests;

  /// No description provided for @authFailureUserDisabled.
  ///
  /// In bn, this message translates to:
  /// **'এই অ্যাকাউন্টটি বন্ধ করা হয়েছে। পরিবারের অ্যাডমিনের সাথে কথা বলুন।'**
  String get authFailureUserDisabled;

  /// No description provided for @authFailureRequiresRecentLogin.
  ///
  /// In bn, this message translates to:
  /// **'নিরাপত্তার জন্য আবার লগ ইন করুন, তারপর চেষ্টা করুন।'**
  String get authFailureRequiresRecentLogin;

  /// No description provided for @authFailureInvalidEmail.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল ঠিকানাটি সঠিক নয়।'**
  String get authFailureInvalidEmail;

  /// No description provided for @authFailureNoCurrentUser.
  ///
  /// In bn, this message translates to:
  /// **'আপনি আগে লগ আউট করেছেন। আবার লগ ইন করুন।'**
  String get authFailureNoCurrentUser;

  /// No description provided for @authFailureValidationRequired.
  ///
  /// In bn, this message translates to:
  /// **'{field} পূরণ করুন।'**
  String authFailureValidationRequired(String field);

  /// No description provided for @authFailureValidationInvalidEmail.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ইমেইল ঠিকানা দিন।'**
  String get authFailureValidationInvalidEmail;

  /// No description provided for @authFailureValidationPasswordTooShort.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড অন্তত ৮ অক্ষরের হতে হবে।'**
  String get authFailureValidationPasswordTooShort;

  /// No description provided for @authFailureUnknown.
  ///
  /// In bn, this message translates to:
  /// **'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।'**
  String get authFailureUnknown;

  /// No description provided for @authFieldEmail.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get authFieldEmail;

  /// No description provided for @authFieldPassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড'**
  String get authFieldPassword;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In bn, this message translates to:
  /// **'আপনার এই কাজটি করার অনুমতি নেই।'**
  String get errorPermissionDenied;

  /// No description provided for @errorNotFound.
  ///
  /// In bn, this message translates to:
  /// **'তথ্যটি খুঁজে পাওয়া যায়নি।'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In bn, this message translates to:
  /// **'কেউ ইতিমধ্যে এই তথ্য পরিবর্তন করেছে। আবার চেষ্টা করুন।'**
  String get errorConflict;

  /// No description provided for @errorNetwork.
  ///
  /// In bn, this message translates to:
  /// **'ইন্টারনেট সংযোগ পাওয়া যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।'**
  String get errorNetwork;

  /// No description provided for @errorUnknown.
  ///
  /// In bn, this message translates to:
  /// **'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।'**
  String get errorUnknown;

  /// No description provided for @errorValidationRequired.
  ///
  /// In bn, this message translates to:
  /// **'{field} পূরণ করুন।'**
  String errorValidationRequired(String field);

  /// No description provided for @errorValidationEmail.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ইমেইল ঠিকানা দিন।'**
  String get errorValidationEmail;

  /// No description provided for @errorValidationPasswordTooShort.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড অন্তত ৮ অক্ষরের হতে হবে।'**
  String get errorValidationPasswordTooShort;

  /// No description provided for @emptyGenericTitle.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কিছু নেই'**
  String get emptyGenericTitle;

  /// No description provided for @emptyGenericMessage.
  ///
  /// In bn, this message translates to:
  /// **'শুরু করতে নিচের বাটনে চাপ দিন।'**
  String get emptyGenericMessage;

  /// No description provided for @emptyNoDataTitle.
  ///
  /// In bn, this message translates to:
  /// **'কোনো তথ্য নেই'**
  String get emptyNoDataTitle;

  /// No description provided for @emptyNoDataMessage.
  ///
  /// In bn, this message translates to:
  /// **'এই তালিকাটি এখন খালি।'**
  String get emptyNoDataMessage;

  /// No description provided for @loadingGeneric.
  ///
  /// In bn, this message translates to:
  /// **'লোড হচ্ছে…'**
  String get loadingGeneric;

  /// No description provided for @offlineBanner.
  ///
  /// In bn, this message translates to:
  /// **'আপনি অফলাইনে আছেন। সংযোগ ফিরলে তথ্য সিঙ্ক হবে।'**
  String get offlineBanner;

  /// No description provided for @settingsTitle.
  ///
  /// In bn, this message translates to:
  /// **'সেটিংস'**
  String get settingsTitle;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপিয়ারেন্স'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeMode.
  ///
  /// In bn, this message translates to:
  /// **'থিম মোড'**
  String get settingsThemeMode;

  /// No description provided for @settingsColourPalette.
  ///
  /// In bn, this message translates to:
  /// **'রঙের প্যালেট'**
  String get settingsColourPalette;

  /// No description provided for @settingsFollowDevice.
  ///
  /// In bn, this message translates to:
  /// **'ডিভাইস অনুসরণ করুন'**
  String get settingsFollowDevice;

  /// No description provided for @settingsFollowDeviceSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার সিস্টেমের আলো / অন্ধকার সেটিং ব্যবহার করবে'**
  String get settingsFollowDeviceSubtitle;

  /// No description provided for @settingsThemeSelected.
  ///
  /// In bn, this message translates to:
  /// **'নির্বাচিত'**
  String get settingsThemeSelected;

  /// No description provided for @settingsThemeSelectedSemantics.
  ///
  /// In bn, this message translates to:
  /// **'{theme} থিম, নির্বাচিত'**
  String settingsThemeSelectedSemantics(String theme);

  /// No description provided for @settingsThemeUnselectedSemantics.
  ///
  /// In bn, this message translates to:
  /// **'{theme} থিম'**
  String settingsThemeUnselectedSemantics(String theme);

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In bn, this message translates to:
  /// **'ভাষা'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In bn, this message translates to:
  /// **'ভাষা নির্বাচন করুন'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageBangla.
  ///
  /// In bn, this message translates to:
  /// **'বাংলা'**
  String get settingsLanguageBangla;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In bn, this message translates to:
  /// **'ইংরেজি'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপের ভাষা তাৎক্ষণিকভাবে পরিবর্তিত হয়'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsBanglaDigits.
  ///
  /// In bn, this message translates to:
  /// **'বাংলা অঙ্ক ব্যবহার করুন'**
  String get settingsBanglaDigits;

  /// No description provided for @settingsBanglaDigitsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সংখ্যা ও তারিখ বাংলা অঙ্কে (০১২৩) দেখাবে'**
  String get settingsBanglaDigitsSubtitle;

  /// No description provided for @settingsLanguageSelectedSemantics.
  ///
  /// In bn, this message translates to:
  /// **'{language} ভাষা, নির্বাচিত'**
  String settingsLanguageSelectedSemantics(String language);

  /// No description provided for @languageNameBn.
  ///
  /// In bn, this message translates to:
  /// **'বাংলা'**
  String get languageNameBn;

  /// No description provided for @languageNameEn.
  ///
  /// In bn, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @devTokensTitle.
  ///
  /// In bn, this message translates to:
  /// **'ডেভ — থিম টোকেন'**
  String get devTokensTitle;

  /// No description provided for @devGalleryTitle.
  ///
  /// In bn, this message translates to:
  /// **'ডেভ — গ্যালারি'**
  String get devGalleryTitle;

  /// No description provided for @homeViewThemeTokens.
  ///
  /// In bn, this message translates to:
  /// **'থিম টোকেন দেখুন'**
  String get homeViewThemeTokens;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
