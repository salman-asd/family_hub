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
    Locale('en'),
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

  /// No description provided for @moduleComingSoonTitle.
  ///
  /// In bn, this message translates to:
  /// **'শীঘ্রই আসছে'**
  String get moduleComingSoonTitle;

  /// No description provided for @moduleComingSoonMessage.
  ///
  /// In bn, this message translates to:
  /// **'এই অংশটি এখনো তৈরি হচ্ছে।'**
  String get moduleComingSoonMessage;

  /// No description provided for @bazarHomeEmptyTitle.
  ///
  /// In bn, this message translates to:
  /// **'বাজার এখনো খালি'**
  String get bazarHomeEmptyTitle;

  /// No description provided for @bazarHomeEmptyMessage.
  ///
  /// In bn, this message translates to:
  /// **'খরচ, বাজার তালিকা ও হিসাবের অংশগুলো ধাপে ধাপে এখানে যোগ হবে।'**
  String get bazarHomeEmptyMessage;

  /// No description provided for @bazarCatalogSetupTitle.
  ///
  /// In bn, this message translates to:
  /// **'স্টার্টার বাজার তালিকা সেট করুন'**
  String get bazarCatalogSetupTitle;

  /// No description provided for @bazarCatalogSetupMessage.
  ///
  /// In bn, this message translates to:
  /// **'শুরু করার জন্য ১১টি ক্যাটাগরি ও ৫৪টি সাধারণ আইটেম যোগ করুন। পরে আপনি সেগুলো সম্পাদনা, যোগ বা লুকাতে পারবেন।'**
  String get bazarCatalogSetupMessage;

  /// No description provided for @bazarCatalogSetupAction.
  ///
  /// In bn, this message translates to:
  /// **'তালিকা তৈরি করুন'**
  String get bazarCatalogSetupAction;

  /// No description provided for @bazarCatalogSetupBusy.
  ///
  /// In bn, this message translates to:
  /// **'বাজার তালিকা তৈরি হচ্ছে…'**
  String get bazarCatalogSetupBusy;

  /// No description provided for @bazarCatalogAskAdminTitle.
  ///
  /// In bn, this message translates to:
  /// **'বাজার তালিকা তৈরি হয়নি'**
  String get bazarCatalogAskAdminTitle;

  /// No description provided for @bazarCatalogAskAdminMessage.
  ///
  /// In bn, this message translates to:
  /// **'বাজার তালিকা তৈরি করতে একজন অ্যাডমিনকে বলুন।'**
  String get bazarCatalogAskAdminMessage;

  /// No description provided for @bazarSettingsTitle.
  ///
  /// In bn, this message translates to:
  /// **'বাজারের সেটিংস'**
  String get bazarSettingsTitle;

  /// No description provided for @unitKg.
  ///
  /// In bn, this message translates to:
  /// **'কেজি'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In bn, this message translates to:
  /// **'গ্রাম'**
  String get unitG;

  /// No description provided for @unitLitre.
  ///
  /// In bn, this message translates to:
  /// **'লিটার'**
  String get unitLitre;

  /// No description provided for @unitPiece.
  ///
  /// In bn, this message translates to:
  /// **'পিস'**
  String get unitPiece;

  /// No description provided for @unitDozen.
  ///
  /// In bn, this message translates to:
  /// **'ডজন'**
  String get unitDozen;

  /// No description provided for @unitPacket.
  ///
  /// In bn, this message translates to:
  /// **'প্যাকেট'**
  String get unitPacket;

  /// No description provided for @unitCylinder.
  ///
  /// In bn, this message translates to:
  /// **'সিলিন্ডার'**
  String get unitCylinder;

  /// No description provided for @bazarFundingFund.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারের তহবিল'**
  String get bazarFundingFund;

  /// No description provided for @bazarFundingMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য পরিশোধিত'**
  String get bazarFundingMember;

  /// No description provided for @bazarAdvancePending.
  ///
  /// In bn, this message translates to:
  /// **'অপেক্ষমাণ'**
  String get bazarAdvancePending;

  /// No description provided for @bazarAdvancePartial.
  ///
  /// In bn, this message translates to:
  /// **'আংশিক সমন্বিত'**
  String get bazarAdvancePartial;

  /// No description provided for @bazarAdvanceSettled.
  ///
  /// In bn, this message translates to:
  /// **'সমন্বিত'**
  String get bazarAdvanceSettled;

  /// No description provided for @bazarAdvanceVoided.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get bazarAdvanceVoided;

  /// No description provided for @bazarErrRequired.
  ///
  /// In bn, this message translates to:
  /// **'এই ঘরটি পূরণ করুন।'**
  String get bazarErrRequired;

  /// No description provided for @bazarErrTooLong.
  ///
  /// In bn, this message translates to:
  /// **'লেখাটি অনেক বড় হয়ে গেছে।'**
  String get bazarErrTooLong;

  /// No description provided for @bazarErrInvalidAmount.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক অঙ্ক লিখুন।'**
  String get bazarErrInvalidAmount;

  /// No description provided for @bazarErrAmountNotPositive.
  ///
  /// In bn, this message translates to:
  /// **'অঙ্কটি শূন্যের বেশি হতে হবে।'**
  String get bazarErrAmountNotPositive;

  /// No description provided for @bazarErrFutureDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ ভবিষ্যতের হতে পারে না।'**
  String get bazarErrFutureDate;

  /// No description provided for @bazarErrQtyUnitRequired.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ ও একক দুটোই দিন।'**
  String get bazarErrQtyUnitRequired;

  /// No description provided for @bazarErrMemberRequired.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যটি বেছে নিন।'**
  String get bazarErrMemberRequired;

  /// No description provided for @bazarErrCategoryRequired.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি বেছে নিন।'**
  String get bazarErrCategoryRequired;

  /// No description provided for @bazarErrItemNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'আইটেমের নাম লিখুন।'**
  String get bazarErrItemNameRequired;

  /// No description provided for @bazarErrTooManyLines.
  ///
  /// In bn, this message translates to:
  /// **'সারি অনেক বেশি; কিছু সরিয়ে দিন।'**
  String get bazarErrTooManyLines;

  /// No description provided for @bazarErrInvalidMonth.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক মাস বেছে নিন।'**
  String get bazarErrInvalidMonth;

  /// No description provided for @bazarErrInvalidRange.
  ///
  /// In bn, this message translates to:
  /// **'শেষ তারিখ শুরুর তারিখের পরে হতে হবে।'**
  String get bazarErrInvalidRange;

  /// No description provided for @bazarErrNegative.
  ///
  /// In bn, this message translates to:
  /// **'অঙ্ক ঋণাত্মক হতে পারে না।'**
  String get bazarErrNegative;

  /// No description provided for @bazarErrTooManyDecimals.
  ///
  /// In bn, this message translates to:
  /// **'সর্বোচ্চ দুই দশমিক স্থান ব্যবহার করুন।'**
  String get bazarErrTooManyDecimals;

  /// No description provided for @bazarErrTooLarge.
  ///
  /// In bn, this message translates to:
  /// **'অঙ্কটি অনেক বড়।'**
  String get bazarErrTooLarge;

  /// No description provided for @bazarErrMonthLocked.
  ///
  /// In bn, this message translates to:
  /// **'এই মাস বন্ধ আছে। খুলতে অ্যাডমিনকে বলুন।'**
  String get bazarErrMonthLocked;

  /// No description provided for @bazarErrAdvanceSettled.
  ///
  /// In bn, this message translates to:
  /// **'এই অগ্রিম আংশিক বা সম্পূর্ণ সমন্বয় হয়ে গেছে।'**
  String get bazarErrAdvanceSettled;

  /// No description provided for @bazarErrOverpayment.
  ///
  /// In bn, this message translates to:
  /// **'বাকি থাকা অঙ্কের চেয়ে বেশি দেওয়া হয়েছে।'**
  String get bazarErrOverpayment;

  /// No description provided for @bazarErrAlreadyClosed.
  ///
  /// In bn, this message translates to:
  /// **'এই মাস ইতিমধ্যে বন্ধ আছে।'**
  String get bazarErrAlreadyClosed;

  /// No description provided for @bazarErrNotClosed.
  ///
  /// In bn, this message translates to:
  /// **'এই মাস বন্ধ নয়।'**
  String get bazarErrNotClosed;

  /// No description provided for @bazarErrReopenNoteRequired.
  ///
  /// In bn, this message translates to:
  /// **'মাসটি কেন খুলছেন তা লিখুন।'**
  String get bazarErrReopenNoteRequired;

  /// No description provided for @bazarErrCatalogNotEmpty.
  ///
  /// In bn, this message translates to:
  /// **'তালিকায় এখনো আইটেম আছে; আগে সেগুলো আর্কাইভ করুন।'**
  String get bazarErrCatalogNotEmpty;

  /// No description provided for @bazarErrDuplicateItem.
  ///
  /// In bn, this message translates to:
  /// **'ঠিক এই ধরনের খরচ সবেমাত্র যোগ হয়েছে। আবার সংরক্ষণের আগে দেখে নিন।'**
  String get bazarErrDuplicateItem;

  /// No description provided for @bazarErrImportAlreadyUndone.
  ///
  /// In bn, this message translates to:
  /// **'এই ইমপোর্ট আগেই বাতিল হয়েছে।'**
  String get bazarErrImportAlreadyUndone;

  /// No description provided for @bazarErrImportHasLockedMonth.
  ///
  /// In bn, this message translates to:
  /// **'ফাইলে বন্ধ মাসের সারি আছে।'**
  String get bazarErrImportHasLockedMonth;

  /// No description provided for @bazarErrConcurrentEdit.
  ///
  /// In bn, this message translates to:
  /// **'আপনার আগেই কেউ এটি বদলেছেন। রিফ্রেশ করে আবার চেষ্টা করুন।'**
  String get bazarErrConcurrentEdit;

  /// No description provided for @bazarErrNotFound.
  ///
  /// In bn, this message translates to:
  /// **'রেকর্ডটি আর নেই। রিফ্রেশ করে আবার চেষ্টা করুন।'**
  String get bazarErrNotFound;

  /// No description provided for @bazarErrNotAllowed.
  ///
  /// In bn, this message translates to:
  /// **'শুধু সংসার ব্যবস্থাপক বা অ্যাডমিন এটি করতে পারেন।'**
  String get bazarErrNotAllowed;

  /// No description provided for @bazarErrUnknown.
  ///
  /// In bn, this message translates to:
  /// **'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।'**
  String get bazarErrUnknown;

  /// No description provided for @profileSetupTitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার প্রোফাইল তৈরি করুন'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupMessage.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারকে জানান আপনি কে।'**
  String get profileSetupMessage;

  /// No description provided for @familyChoiceTitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারে যোগ দিন বা নতুন তৈরি করুন'**
  String get familyChoiceTitle;

  /// No description provided for @familyChoiceMessage.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পরিবার তৈরি করুন, অথবা আমন্ত্রণ কোড দিয়ে যোগ দিন।'**
  String get familyChoiceMessage;

  /// No description provided for @pendingTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনের অপেক্ষায়'**
  String get pendingTitle;

  /// No description provided for @pendingMessage.
  ///
  /// In bn, this message translates to:
  /// **'চালিয়ে যেতে পরিবারের অ্যাডমিনকে আপনার অনুরোধ অনুমোদন করতে হবে।'**
  String get pendingMessage;

  /// No description provided for @disabledTitle.
  ///
  /// In bn, this message translates to:
  /// **'প্রবেশ বন্ধ আছে'**
  String get disabledTitle;

  /// No description provided for @disabledMessage.
  ///
  /// In bn, this message translates to:
  /// **'এই পরিবারে আপনার প্রবেশ বন্ধ করা হয়েছে। অনুগ্রহ করে অ্যাডমিনের সাথে যোগাযোগ করুন।'**
  String get disabledMessage;

  /// No description provided for @placeholderContinueProfile.
  ///
  /// In bn, this message translates to:
  /// **'চালিয়ে যান (অস্থায়ী)'**
  String get placeholderContinueProfile;

  /// No description provided for @placeholderCreateFamily.
  ///
  /// In bn, this message translates to:
  /// **'পরীক্ষামূলক পরিবার তৈরি করুন (অস্থায়ী)'**
  String get placeholderCreateFamily;

  /// No description provided for @placeholderApproveMe.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদিত ধরে নিন (অস্থায়ী)'**
  String get placeholderApproveMe;

  /// No description provided for @notFoundTitle.
  ///
  /// In bn, this message translates to:
  /// **'পাতাটি পাওয়া যায়নি'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In bn, this message translates to:
  /// **'আপনি যে পাতাটি খুলেছেন সেটি নেই।'**
  String get notFoundMessage;

  /// No description provided for @notFoundAction.
  ///
  /// In bn, this message translates to:
  /// **'হোমে যান'**
  String get notFoundAction;

  /// No description provided for @profileFullName.
  ///
  /// In bn, this message translates to:
  /// **'পুরো নাম'**
  String get profileFullName;

  /// No description provided for @profileNickname.
  ///
  /// In bn, this message translates to:
  /// **'ডাকনাম (ঐচ্ছিক)'**
  String get profileNickname;

  /// No description provided for @profileGender.
  ///
  /// In bn, this message translates to:
  /// **'লিঙ্গ (ঐচ্ছিক)'**
  String get profileGender;

  /// No description provided for @genderMale.
  ///
  /// In bn, this message translates to:
  /// **'পুরুষ'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In bn, this message translates to:
  /// **'নারী'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get genderOther;

  /// No description provided for @genderNone.
  ///
  /// In bn, this message translates to:
  /// **'বলতে চাই না'**
  String get genderNone;

  /// No description provided for @profileRelationship.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get profileRelationship;

  /// No description provided for @profileAvatar.
  ///
  /// In bn, this message translates to:
  /// **'একটি অ্যাভাটার বেছে নিন'**
  String get profileAvatar;

  /// No description provided for @profileSave.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল সংরক্ষণ করুন'**
  String get profileSave;

  /// No description provided for @profileSpouse.
  ///
  /// In bn, this message translates to:
  /// **'স্বামী/স্ত্রী (ঐচ্ছিক)'**
  String get profileSpouse;

  /// No description provided for @profileSpouseNone.
  ///
  /// In bn, this message translates to:
  /// **'কেউ নয়'**
  String get profileSpouseNone;

  /// No description provided for @relFather.
  ///
  /// In bn, this message translates to:
  /// **'বাবা'**
  String get relFather;

  /// No description provided for @relMother.
  ///
  /// In bn, this message translates to:
  /// **'মা'**
  String get relMother;

  /// No description provided for @relSon.
  ///
  /// In bn, this message translates to:
  /// **'ছেলে'**
  String get relSon;

  /// No description provided for @relDaughter.
  ///
  /// In bn, this message translates to:
  /// **'মেয়ে'**
  String get relDaughter;

  /// No description provided for @relHusband.
  ///
  /// In bn, this message translates to:
  /// **'স্বামী'**
  String get relHusband;

  /// No description provided for @relWife.
  ///
  /// In bn, this message translates to:
  /// **'স্ত্রী'**
  String get relWife;

  /// No description provided for @relHousewife.
  ///
  /// In bn, this message translates to:
  /// **'গৃহিণী'**
  String get relHousewife;

  /// No description provided for @relDaughterInLaw.
  ///
  /// In bn, this message translates to:
  /// **'পুত্রবধূ'**
  String get relDaughterInLaw;

  /// No description provided for @relSonInLaw.
  ///
  /// In bn, this message translates to:
  /// **'জামাই'**
  String get relSonInLaw;

  /// No description provided for @relOther.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get relOther;

  /// No description provided for @familyCreateAction.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পরিবার তৈরি করুন'**
  String get familyCreateAction;

  /// No description provided for @familyJoinAction.
  ///
  /// In bn, this message translates to:
  /// **'কোড দিয়ে যোগ দিন'**
  String get familyJoinAction;

  /// No description provided for @familyNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারের নাম'**
  String get familyNameLabel;

  /// No description provided for @familyCreateSubmit.
  ///
  /// In bn, this message translates to:
  /// **'পরিবার তৈরি করুন'**
  String get familyCreateSubmit;

  /// No description provided for @joinCodeLabel.
  ///
  /// In bn, this message translates to:
  /// **'আমন্ত্রণ কোড'**
  String get joinCodeLabel;

  /// No description provided for @joinSubmit.
  ///
  /// In bn, this message translates to:
  /// **'যোগদানের অনুরোধ করুন'**
  String get joinSubmit;

  /// No description provided for @joinHint.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারের অ্যাডমিনের কাছ থেকে ৮ অক্ষরের কোড নিন।'**
  String get joinHint;

  /// No description provided for @membersTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get membersTitle;

  /// No description provided for @membersPending.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনের অপেক্ষায়'**
  String get membersPending;

  /// No description provided for @membersActive.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয়'**
  String get membersActive;

  /// No description provided for @membersDisabled.
  ///
  /// In bn, this message translates to:
  /// **'নিষ্ক্রিয়'**
  String get membersDisabled;

  /// No description provided for @memberYou.
  ///
  /// In bn, this message translates to:
  /// **'আপনি'**
  String get memberYou;

  /// No description provided for @memberApprove.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন'**
  String get memberApprove;

  /// No description provided for @memberReject.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাখ্যান'**
  String get memberReject;

  /// No description provided for @memberDisable.
  ///
  /// In bn, this message translates to:
  /// **'নিষ্ক্রিয় করুন'**
  String get memberDisable;

  /// No description provided for @memberReenable.
  ///
  /// In bn, this message translates to:
  /// **'আবার সক্রিয় করুন'**
  String get memberReenable;

  /// No description provided for @roleAdmin.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিন'**
  String get roleAdmin;

  /// No description provided for @roleModerator.
  ///
  /// In bn, this message translates to:
  /// **'সংসার ব্যবস্থাপক'**
  String get roleModerator;

  /// No description provided for @roleMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get roleMember;

  /// No description provided for @memberProfileTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের প্রোফাইল'**
  String get memberProfileTitle;

  /// No description provided for @memberEditProfile.
  ///
  /// In bn, this message translates to:
  /// **'আমার প্রোফাইল সম্পাদনা'**
  String get memberEditProfile;

  /// No description provided for @memberRoleLabel.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা'**
  String get memberRoleLabel;

  /// No description provided for @memberStatusLabel.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get memberStatusLabel;

  /// No description provided for @invitationsTitle.
  ///
  /// In bn, this message translates to:
  /// **'আমন্ত্রণ'**
  String get invitationsTitle;

  /// No description provided for @invitationCreate.
  ///
  /// In bn, this message translates to:
  /// **'আমন্ত্রণ কোড তৈরি করুন'**
  String get invitationCreate;

  /// No description provided for @invitationCopy.
  ///
  /// In bn, this message translates to:
  /// **'কোড কপি করুন'**
  String get invitationCopy;

  /// No description provided for @invitationCopied.
  ///
  /// In bn, this message translates to:
  /// **'কোড কপি হয়েছে'**
  String get invitationCopied;

  /// No description provided for @invitationExpiresOn.
  ///
  /// In bn, this message translates to:
  /// **'মেয়াদ শেষ'**
  String get invitationExpiresOn;

  /// No description provided for @invStatusActive.
  ///
  /// In bn, this message translates to:
  /// **'অব্যবহৃত'**
  String get invStatusActive;

  /// No description provided for @invStatusUsed.
  ///
  /// In bn, this message translates to:
  /// **'ব্যবহৃত'**
  String get invStatusUsed;

  /// No description provided for @invStatusExpired.
  ///
  /// In bn, this message translates to:
  /// **'মেয়াদোত্তীর্ণ'**
  String get invStatusExpired;

  /// No description provided for @invStatusRevoked.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get invStatusRevoked;

  /// No description provided for @invitationsEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো আমন্ত্রণ নেই'**
  String get invitationsEmpty;

  /// No description provided for @rolesTitle.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা'**
  String get rolesTitle;

  /// No description provided for @rolesMakeAdmin.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিন বানান'**
  String get rolesMakeAdmin;

  /// No description provided for @rolesTransferTitle.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিনের দায়িত্ব হস্তান্তর করবেন?'**
  String get rolesTransferTitle;

  /// No description provided for @rolesTransferMessage.
  ///
  /// In bn, this message translates to:
  /// **'আপনি সাধারণ সদস্য হয়ে যাবেন।'**
  String get rolesTransferMessage;

  /// No description provided for @actionConfirm.
  ///
  /// In bn, this message translates to:
  /// **'নিশ্চিত করুন'**
  String get actionConfirm;

  /// No description provided for @familySettingsTitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারের সেটিংস'**
  String get familySettingsTitle;

  /// No description provided for @settingsTimezone.
  ///
  /// In bn, this message translates to:
  /// **'সময় অঞ্চল'**
  String get settingsTimezone;

  /// No description provided for @settingsCurrency.
  ///
  /// In bn, this message translates to:
  /// **'মুদ্রা'**
  String get settingsCurrency;

  /// No description provided for @settingsModules.
  ///
  /// In bn, this message translates to:
  /// **'মডিউল'**
  String get settingsModules;

  /// No description provided for @settingsSaved.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষিত হয়েছে'**
  String get settingsSaved;

  /// No description provided for @famFailureNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'একটি নাম লিখুন।'**
  String get famFailureNameRequired;

  /// No description provided for @famFailureCodeInvalid.
  ///
  /// In bn, this message translates to:
  /// **'কোডটি সঠিক নয়। কোডে ৮টি অক্ষর ও সংখ্যা থাকে।'**
  String get famFailureCodeInvalid;

  /// No description provided for @famFailureCodeNotFound.
  ///
  /// In bn, this message translates to:
  /// **'এই কোডে কোনো আমন্ত্রণ পাওয়া যায়নি।'**
  String get famFailureCodeNotFound;

  /// No description provided for @famFailureCodeUsed.
  ///
  /// In bn, this message translates to:
  /// **'এই কোডটি আগেই ব্যবহার করা হয়েছে।'**
  String get famFailureCodeUsed;

  /// No description provided for @famFailureCodeExpired.
  ///
  /// In bn, this message translates to:
  /// **'কোডটির মেয়াদ শেষ। নতুন কোড চান।'**
  String get famFailureCodeExpired;

  /// No description provided for @famFailureCodeRevoked.
  ///
  /// In bn, this message translates to:
  /// **'কোডটি বাতিল করা হয়েছে।'**
  String get famFailureCodeRevoked;

  /// No description provided for @famFailureAlreadyMember.
  ///
  /// In bn, this message translates to:
  /// **'আপনি ইতিমধ্যে এই পরিবারে আছেন।'**
  String get famFailureAlreadyMember;

  /// No description provided for @famFailureLastAdmin.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারে অন্তত একজন অ্যাডমিন থাকতে হবে। আগে অন্য কাউকে অ্যাডমিন বানান।'**
  String get famFailureLastAdmin;

  /// No description provided for @famFailureTooManyAdmins.
  ///
  /// In bn, this message translates to:
  /// **'একটি পরিবারে সর্বোচ্চ তিনজন অ্যাডমিন থাকতে পারে।'**
  String get famFailureTooManyAdmins;

  /// No description provided for @famFailureNotAllowed.
  ///
  /// In bn, this message translates to:
  /// **'এটি করার অনুমতি আপনার নেই।'**
  String get famFailureNotAllowed;

  /// No description provided for @famFailureProfileRequired.
  ///
  /// In bn, this message translates to:
  /// **'আগে আপনার প্রোফাইল সম্পূর্ণ করুন।'**
  String get famFailureProfileRequired;

  /// No description provided for @avatarOption.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাভাটার {number}'**
  String avatarOption(String number);

  /// Status label for a chore occurrence that is scheduled.
  ///
  /// In bn, this message translates to:
  /// **'সময় নির্ধারিত'**
  String get statusScheduled;

  /// No description provided for @statusInProgress.
  ///
  /// In bn, this message translates to:
  /// **'চলছে'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন'**
  String get statusCompleted;

  /// No description provided for @statusVerified.
  ///
  /// In bn, this message translates to:
  /// **'যাচাইকৃত'**
  String get statusVerified;

  /// No description provided for @statusOverdue.
  ///
  /// In bn, this message translates to:
  /// **'সময় পার হয়েছে'**
  String get statusOverdue;

  /// 'See all' link on a section header.
  ///
  /// In bn, this message translates to:
  /// **'সব দেখুন'**
  String get commonSeeAll;

  /// No description provided for @errorViewTitle.
  ///
  /// In bn, this message translates to:
  /// **'কিছু ভুল হয়েছে'**
  String get errorViewTitle;

  /// Screen-reader label for a loading skeleton.
  ///
  /// In bn, this message translates to:
  /// **'লোড হচ্ছে'**
  String get loadingSemantics;

  /// No description provided for @progressSemantics.
  ///
  /// In bn, this message translates to:
  /// **'{label}, {percent} শতাংশ সম্পন্ন'**
  String progressSemantics(String label, String percent);

  /// No description provided for @thumbSemantics.
  ///
  /// In bn, this message translates to:
  /// **'{name} ছবি'**
  String thumbSemantics(String name);

  /// No description provided for @galleryAvatar.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাভাটার'**
  String get galleryAvatar;

  /// No description provided for @galleryItemThumb.
  ///
  /// In bn, this message translates to:
  /// **'জিনিসের ছবি'**
  String get galleryItemThumb;

  /// No description provided for @galleryStatusChip.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থার চিপ'**
  String get galleryStatusChip;

  /// No description provided for @gallerySectionHeader.
  ///
  /// In bn, this message translates to:
  /// **'সেকশন হেডার'**
  String get gallerySectionHeader;

  /// No description provided for @galleryAppCard.
  ///
  /// In bn, this message translates to:
  /// **'কার্ড'**
  String get galleryAppCard;

  /// No description provided for @galleryMoneyText.
  ///
  /// In bn, this message translates to:
  /// **'টাকার লেখা'**
  String get galleryMoneyText;

  /// No description provided for @galleryProgressRing.
  ///
  /// In bn, this message translates to:
  /// **'প্রগ্রেস রিং'**
  String get galleryProgressRing;

  /// No description provided for @galleryEmptyState.
  ///
  /// In bn, this message translates to:
  /// **'খালি অবস্থা'**
  String get galleryEmptyState;

  /// No description provided for @galleryLoadingView.
  ///
  /// In bn, this message translates to:
  /// **'লোডিং দৃশ্য'**
  String get galleryLoadingView;

  /// No description provided for @galleryErrorView.
  ///
  /// In bn, this message translates to:
  /// **'ত্রুটির দৃশ্য'**
  String get galleryErrorView;

  /// No description provided for @galleryPillBottomBar.
  ///
  /// In bn, this message translates to:
  /// **'পিল নেভিগেশন বার'**
  String get galleryPillBottomBar;

  /// No description provided for @gallerySampleTitle.
  ///
  /// In bn, this message translates to:
  /// **'নমুনা শিরোনাম'**
  String get gallerySampleTitle;

  /// No description provided for @gallerySampleMessage.
  ///
  /// In bn, this message translates to:
  /// **'এটি একটি নমুনা বার্তা যা ওভারফ্লো যাচাই করে।'**
  String get gallerySampleMessage;

  /// No description provided for @gallerySampleItemName.
  ///
  /// In bn, this message translates to:
  /// **'আলু'**
  String get gallerySampleItemName;

  /// No description provided for @gallerySamplePersonName.
  ///
  /// In bn, this message translates to:
  /// **'করিম উদ্দিন'**
  String get gallerySamplePersonName;

  /// No description provided for @syncWaitingTitle.
  ///
  /// In bn, this message translates to:
  /// **'সংযোগের অপেক্ষায়…'**
  String get syncWaitingTitle;

  /// No description provided for @syncWaitingMessage.
  ///
  /// In bn, this message translates to:
  /// **'ইন্টারনেট সংযোগ আছে কিনা দেখুন, তারপর আবার চেষ্টা করুন। আপনার তথ্য নিরাপদ আছে।'**
  String get syncWaitingMessage;

  /// No description provided for @syncSavedOffline.
  ///
  /// In bn, this message translates to:
  /// **'এই ডিভাইসে সংরক্ষিত হয়েছে — অনলাইনে এলে সিঙ্ক হবে'**
  String get syncSavedOffline;

  /// No description provided for @syncBannerSyncing.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি পরিবর্তন সিঙ্ক হচ্ছে'**
  String syncBannerSyncing(int count);

  /// No description provided for @syncBannerOffline.
  ///
  /// In bn, this message translates to:
  /// **'অফলাইন — {count}টি পরিবর্তন অপেক্ষায়'**
  String syncBannerOffline(int count);

  /// No description provided for @gallerySyncBanner.
  ///
  /// In bn, this message translates to:
  /// **'সিঙ্ক ব্যানার'**
  String get gallerySyncBanner;

  /// No description provided for @famFailureAlreadyInFamily.
  ///
  /// In bn, this message translates to:
  /// **'আপনি ইতিমধ্যে একটি পরিবারে আছেন। আগে সেটি ছেড়ে দিন।'**
  String get famFailureAlreadyInFamily;

  /// No description provided for @familyLeave.
  ///
  /// In bn, this message translates to:
  /// **'পরিবার ছেড়ে যান'**
  String get familyLeave;

  /// No description provided for @familyLeaveConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিবার ছেড়ে যাবেন?'**
  String get familyLeaveConfirmTitle;

  /// No description provided for @familyLeaveConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'আপনার আগের কাজ ও হিসাবের ইতিহাস পরিবারে থেকে যাবে। পরে আপনি নতুন পরিবার খুলতে বা অন্য পরিবারে যোগ দিতে পারবেন।'**
  String get familyLeaveConfirmBody;

  /// No description provided for @familyLeaveLastAdminReason.
  ///
  /// In bn, this message translates to:
  /// **'আপনিই একমাত্র অ্যাডমিন। ছেড়ে যাওয়ার আগে আরেকজনকে অ্যাডমিন করুন।'**
  String get familyLeaveLastAdminReason;

  /// No description provided for @pendingCancelRequest.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ বাতিল করুন'**
  String get pendingCancelRequest;

  /// No description provided for @invitationRevoke.
  ///
  /// In bn, this message translates to:
  /// **'কোড বাতিল করুন'**
  String get invitationRevoke;

  /// No description provided for @invitationRevokeConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'কোডটি বাতিল করবেন?'**
  String get invitationRevokeConfirmTitle;

  /// No description provided for @invitationRevokeConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'এই কোড দিয়ে আর কেউ যোগ দিতে পারবে না।'**
  String get invitationRevokeConfirmBody;

  /// No description provided for @securityTitle.
  ///
  /// In bn, this message translates to:
  /// **'নিরাপত্তা'**
  String get securityTitle;

  /// No description provided for @securityChangePassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড পরিবর্তন'**
  String get securityChangePassword;

  /// No description provided for @securityCurrentPassword.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান পাসওয়ার্ড'**
  String get securityCurrentPassword;

  /// No description provided for @securityNewPassword.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড'**
  String get securityNewPassword;

  /// No description provided for @securityPasswordChanged.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড পরিবর্তন হয়েছে।'**
  String get securityPasswordChanged;

  /// No description provided for @securityPasswordSame.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড বর্তমানটির থেকে আলাদা হতে হবে।'**
  String get securityPasswordSame;

  /// No description provided for @securityCurrentPasswordRequired.
  ///
  /// In bn, this message translates to:
  /// **'আপনার বর্তমান পাসওয়ার্ড লিখুন।'**
  String get securityCurrentPasswordRequired;

  /// No description provided for @securityCurrentPasswordWrong.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান পাসওয়ার্ডটি সঠিক নয়।'**
  String get securityCurrentPasswordWrong;

  /// No description provided for @securityDeleteTitle.
  ///
  /// In bn, this message translates to:
  /// **'আমার অ্যাকাউন্ট মুছুন'**
  String get securityDeleteTitle;

  /// No description provided for @securityDeleteBody.
  ///
  /// In bn, this message translates to:
  /// **'আপনি পরিবার ছেড়ে যাবেন এবং আপনার সাইন-ইন মুছে যাবে। পরিবারের ইতিহাস ঠিক রাখতে পুরোনো রেকর্ডে আপনার নাম থাকবে।'**
  String get securityDeleteBody;

  /// No description provided for @securityDeletePending.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলা শেষ হয়নি। শেষ করতে পাসওয়ার্ড লিখুন।'**
  String get securityDeletePending;

  /// No description provided for @securityDeleteAction.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট মুছুন'**
  String get securityDeleteAction;

  /// No description provided for @securityDeleteFinish.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলা শেষ করুন'**
  String get securityDeleteFinish;

  /// No description provided for @securityDeleteConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার অ্যাকাউন্ট মুছবেন?'**
  String get securityDeleteConfirmTitle;

  /// No description provided for @securityDeleteConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'এটি আর ফেরানো যাবে না।'**
  String get securityDeleteConfirmBody;

  /// No description provided for @accountDeleteLastAdminHasMembers.
  ///
  /// In bn, this message translates to:
  /// **'আপনি একমাত্র অ্যাডমিন এবং পরিবারে আরও সদস্য আছেন। আগে অ্যাডমিনের দায়িত্ব হস্তান্তর করুন।'**
  String get accountDeleteLastAdminHasMembers;

  /// No description provided for @relationshipsTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্কের তালিকা'**
  String get relationshipsTitle;

  /// No description provided for @relationshipsHint.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি-করা সম্পর্কগুলো পরিবর্তন করা যায় না। নিজের সম্পর্ক যোগ, নাম পরিবর্তন বা বন্ধ করতে পারেন।'**
  String get relationshipsHint;

  /// No description provided for @relationshipsAdd.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক যোগ করুন'**
  String get relationshipsAdd;

  /// No description provided for @relationshipsLabelBn.
  ///
  /// In bn, this message translates to:
  /// **'বাংলায় নাম'**
  String get relationshipsLabelBn;

  /// No description provided for @relationshipsLabelEn.
  ///
  /// In bn, this message translates to:
  /// **'ইংরেজিতে নাম'**
  String get relationshipsLabelEn;

  /// No description provided for @relationshipsSpouseRelevant.
  ///
  /// In bn, this message translates to:
  /// **'স্বামী/স্ত্রী বাছাই দেখান'**
  String get relationshipsSpouseRelevant;

  /// No description provided for @relationshipsBuiltIn.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি-করা'**
  String get relationshipsBuiltIn;

  /// No description provided for @relationshipsActive.
  ///
  /// In bn, this message translates to:
  /// **'চালু'**
  String get relationshipsActive;

  /// No description provided for @relationshipsDisabled.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ'**
  String get relationshipsDisabled;

  /// No description provided for @relationshipsEnable.
  ///
  /// In bn, this message translates to:
  /// **'চালু করুন'**
  String get relationshipsEnable;

  /// No description provided for @relationshipsDisable.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করুন'**
  String get relationshipsDisable;

  /// No description provided for @relationshipsFailureLabel.
  ///
  /// In bn, this message translates to:
  /// **'একটি নাম লিখুন (সর্বোচ্চ ৪০ অক্ষর)।'**
  String get relationshipsFailureLabel;

  /// No description provided for @relationshipsFailureTooMany.
  ///
  /// In bn, this message translates to:
  /// **'তালিকা পূর্ণ।'**
  String get relationshipsFailureTooMany;

  /// No description provided for @relationshipsFailureBuiltIn.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি-করা সম্পর্ক পরিবর্তন করা যায় না।'**
  String get relationshipsFailureBuiltIn;

  /// No description provided for @activityFamilyCreated.
  ///
  /// In bn, this message translates to:
  /// **'পরিবার “{familyName}” তৈরি হয়েছে'**
  String activityFamilyCreated(String familyName);

  /// No description provided for @activityFamilyUpdated.
  ///
  /// In bn, this message translates to:
  /// **'পরিবারের সেটিংস হালনাগাদ হয়েছে'**
  String get activityFamilyUpdated;

  /// No description provided for @activityMemberRequested.
  ///
  /// In bn, this message translates to:
  /// **'{memberName} যোগ দিতে অনুরোধ করেছেন'**
  String activityMemberRequested(String memberName);

  /// No description provided for @activityMemberApproved.
  ///
  /// In bn, this message translates to:
  /// **'{memberName}-কে অনুমোদন দেওয়া হয়েছে'**
  String activityMemberApproved(String memberName);

  /// No description provided for @activityMemberRejected.
  ///
  /// In bn, this message translates to:
  /// **'{memberName}-কে গ্রহণ করা হয়নি'**
  String activityMemberRejected(String memberName);

  /// No description provided for @activityMemberDisabled.
  ///
  /// In bn, this message translates to:
  /// **'{memberName}-কে বন্ধ করা হয়েছে'**
  String activityMemberDisabled(String memberName);

  /// No description provided for @activityMemberRoleChanged.
  ///
  /// In bn, this message translates to:
  /// **'{memberName} এখন {newRole}'**
  String activityMemberRoleChanged(String memberName, String newRole);

  /// No description provided for @activityAdminTransferred.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিনের দায়িত্ব {memberName}-কে দেওয়া হয়েছে'**
  String activityAdminTransferred(String memberName);

  /// No description provided for @activityMemberLeft.
  ///
  /// In bn, this message translates to:
  /// **'{memberName} পরিবার ছেড়ে গেছেন'**
  String activityMemberLeft(String memberName);

  /// No description provided for @activityMemberCancelled.
  ///
  /// In bn, this message translates to:
  /// **'{memberName} অনুরোধ প্রত্যাহার করেছেন'**
  String activityMemberCancelled(String memberName);

  /// No description provided for @activityInvitationCreated.
  ///
  /// In bn, this message translates to:
  /// **'আমন্ত্রণ {code} তৈরি হয়েছে'**
  String activityInvitationCreated(String code);

  /// No description provided for @activityInvitationRevoked.
  ///
  /// In bn, this message translates to:
  /// **'আমন্ত্রণ {code} বাতিল হয়েছে'**
  String activityInvitationRevoked(String code);

  /// No description provided for @activityBazarCatalogSeeded.
  ///
  /// In bn, this message translates to:
  /// **'{categories}টি ক্যাটাগরি ও {items}টি আইটেম দিয়ে বাজারের তালিকা চালু হয়েছে'**
  String activityBazarCatalogSeeded(String categories, String items);

  /// No description provided for @activityBazarCategoryCreated.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি “{name}” যোগ করা হয়েছে'**
  String activityBazarCategoryCreated(String name);

  /// No description provided for @activityBazarCategoryUpdated.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি “{name}” হালনাগাদ হয়েছে'**
  String activityBazarCategoryUpdated(String name);

  /// No description provided for @activityBazarCategoryDeactivated.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি “{name}” আর্কাইভ করা হয়েছে'**
  String activityBazarCategoryDeactivated(String name);

  /// No description provided for @activityBazarItemCreated.
  ///
  /// In bn, this message translates to:
  /// **'আইটেম “{name}” যোগ করা হয়েছে'**
  String activityBazarItemCreated(String name);

  /// No description provided for @activityBazarItemUpdated.
  ///
  /// In bn, this message translates to:
  /// **'আইটেম “{name}” হালনাগাদ হয়েছে'**
  String activityBazarItemUpdated(String name);

  /// No description provided for @activityBazarItemDeactivated.
  ///
  /// In bn, this message translates to:
  /// **'আইটেম “{name}” আর্কাইভ করা হয়েছে'**
  String activityBazarItemDeactivated(String name);

  /// No description provided for @activityBazarExpenseCreated.
  ///
  /// In bn, this message translates to:
  /// **'{item} কেনা হয়েছে {amount} দিয়ে ({funding})'**
  String activityBazarExpenseCreated(
    String item,
    String amount,
    String funding,
  );

  /// No description provided for @activityBazarExpenseUpdated.
  ///
  /// In bn, this message translates to:
  /// **'{item} সম্পাদনা করা হয়েছে ({fields})'**
  String activityBazarExpenseUpdated(String item, String fields);

  /// No description provided for @activityBazarExpenseDeleted.
  ///
  /// In bn, this message translates to:
  /// **'{item} মুছে ফেলা হয়েছে ({amount})'**
  String activityBazarExpenseDeleted(String item, String amount);

  /// No description provided for @activityBazarExpenseRestored.
  ///
  /// In bn, this message translates to:
  /// **'{item} ফিরিয়ে আনা হয়েছে ({amount})'**
  String activityBazarExpenseRestored(String item, String amount);

  /// No description provided for @activityBazarTripCreated.
  ///
  /// In bn, this message translates to:
  /// **'{lines}টি আইটেমের বাজার যাত্রা {amount} দিয়ে সংরক্ষণ হয়েছে'**
  String activityBazarTripCreated(String lines, String amount);

  /// No description provided for @activityBazarBudgetSaved.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এর বাজেট {amount} নির্ধারণ করা হয়েছে'**
  String activityBazarBudgetSaved(String month, String amount);

  /// No description provided for @activityBazarSettingsUpdated.
  ///
  /// In bn, this message translates to:
  /// **'বাজারের সেটিংস হালনাগাদ হয়েছে'**
  String get activityBazarSettingsUpdated;

  /// No description provided for @activityBazarContributionPlanSet.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এ {member}-এর চাঁদা {amount} নির্ধারণ করা হয়েছে'**
  String activityBazarContributionPlanSet(
    String month,
    String member,
    String amount,
  );

  /// No description provided for @activityBazarContributionRecorded.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এ {member}-এর {amount} চাঁদা রেকর্ড করা হয়েছে'**
  String activityBazarContributionRecorded(
    String month,
    String member,
    String amount,
  );

  /// No description provided for @activityBazarContributionVoided.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এ {member}-এর {amount} চাঁদা বাতিল করা হয়েছে'**
  String activityBazarContributionVoided(
    String month,
    String member,
    String amount,
  );

  /// No description provided for @activityBazarContributionRequested.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এর জন্য {member} {amount} দিতে চেয়েছেন'**
  String activityBazarContributionRequested(
    String month,
    String member,
    String amount,
  );

  /// No description provided for @activityBazarContributionRequestEdited.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এর জন্য {member} {amount} দেওয়ার অনুরোধ সম্পাদনা করেছেন'**
  String activityBazarContributionRequestEdited(
    String month,
    String member,
    String amount,
  );

  /// No description provided for @activityBazarContributionRequestCancelled.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এর জন্য {member} {amount} দেওয়ার অনুরোধ প্রত্যাহার করেছেন'**
  String activityBazarContributionRequestCancelled(
    String month,
    String member,
    String amount,
  );

  /// No description provided for @activityBazarContributionApproved.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এ {member}-এর {amount} চাঁদা অনুমোদিত হয়েছে'**
  String activityBazarContributionApproved(
    String month,
    String member,
    String amount,
  );

  /// No description provided for @activityBazarContributionRejected.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এ {member}-এর {amount} চাঁদা গ্রহণ করা হয়নি ({reason})'**
  String activityBazarContributionRejected(
    String month,
    String member,
    String amount,
    String reason,
  );

  /// No description provided for @activityBazarContributionChangeRequested.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এর জন্য {member} {old} থেকে {amount}-এ চাঁদা বদলাতে বলেছেন'**
  String activityBazarContributionChangeRequested(
    String month,
    String member,
    String amount,
    String old,
  );

  /// No description provided for @activityBazarContributionChangeApproved.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এ {member}-এর চাঁদা {old} থেকে {amount}-এ বদলের অনুমোদন হয়েছে'**
  String activityBazarContributionChangeApproved(
    String month,
    String member,
    String amount,
    String old,
  );

  /// No description provided for @activityBazarContributionChangeRejected.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এ {member}-এর চাঁদা {old} থেকে {amount}-এ বদলের অনুমোদন হয়নি'**
  String activityBazarContributionChangeRejected(
    String month,
    String member,
    String amount,
    String old,
  );

  /// No description provided for @activityBazarOpeningBalanceSet.
  ///
  /// In bn, this message translates to:
  /// **'{month}-এর প্রারম্ভিক ব্যালেন্স {amount}'**
  String activityBazarOpeningBalanceSet(String month, String amount);

  /// No description provided for @activityBazarAdvanceSettled.
  ///
  /// In bn, this message translates to:
  /// **'{member}-এর অগ্রিম {amount} সমন্বয় হয়েছে ({status})'**
  String activityBazarAdvanceSettled(
    String member,
    String amount,
    String status,
  );

  /// No description provided for @activityBazarMonthClosed.
  ///
  /// In bn, this message translates to:
  /// **'{month} বন্ধ করা হয়েছে, ব্যালেন্স {balance}'**
  String activityBazarMonthClosed(String month, String balance);

  /// No description provided for @activityBazarMonthReopened.
  ///
  /// In bn, this message translates to:
  /// **'{month} আবার খোলা হয়েছে ({note})'**
  String activityBazarMonthReopened(String month, String note);

  /// No description provided for @activityBazarImportCompleted.
  ///
  /// In bn, this message translates to:
  /// **'ইমপোর্ট শেষ: {rows}টি সারি, {amount}'**
  String activityBazarImportCompleted(String rows, String amount);

  /// No description provided for @activityBazarImportUndone.
  ///
  /// In bn, this message translates to:
  /// **'ইমপোর্ট বাতিল: {rows}টি সারি, {amount}'**
  String activityBazarImportUndone(String rows, String amount);

  /// No description provided for @activityUnknown.
  ///
  /// In bn, this message translates to:
  /// **'কিছু পরিবর্তন হয়েছে'**
  String get activityUnknown;

  /// No description provided for @galleryMonthSwitcher.
  ///
  /// In bn, this message translates to:
  /// **'মাস পরিবর্তন'**
  String get galleryMonthSwitcher;

  /// No description provided for @galleryAmountField.
  ///
  /// In bn, this message translates to:
  /// **'টাকার ঘর'**
  String get galleryAmountField;

  /// No description provided for @galleryTotalDisplay.
  ///
  /// In bn, this message translates to:
  /// **'মোটের প্রদর্শন'**
  String get galleryTotalDisplay;

  /// No description provided for @galleryProgressBarStatus.
  ///
  /// In bn, this message translates to:
  /// **'অগ্রগতির বার'**
  String get galleryProgressBarStatus;

  /// No description provided for @galleryDaySectionHeader.
  ///
  /// In bn, this message translates to:
  /// **'দিনের শিরোনাম'**
  String get galleryDaySectionHeader;

  /// No description provided for @galleryPersonPicker.
  ///
  /// In bn, this message translates to:
  /// **'ব্যক্তি নির্বাচন'**
  String get galleryPersonPicker;

  /// No description provided for @galleryCategoryBadge.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি ব্যাজ'**
  String get galleryCategoryBadge;

  /// No description provided for @gallerySampleAmountLabel.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get gallerySampleAmountLabel;

  /// No description provided for @gallerySampleTotalLabel.
  ///
  /// In bn, this message translates to:
  /// **'মোট'**
  String get gallerySampleTotalLabel;

  /// No description provided for @gallerySampleBudgetLabel.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক বাজার বাজেট'**
  String get gallerySampleBudgetLabel;

  /// No description provided for @gallerySampleNoLimitLabel.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সীমা নেই'**
  String get gallerySampleNoLimitLabel;

  /// No description provided for @gallerySampleCategoryName.
  ///
  /// In bn, this message translates to:
  /// **'সবজি'**
  String get gallerySampleCategoryName;

  /// No description provided for @gallerySampleLongCategoryName.
  ///
  /// In bn, this message translates to:
  /// **'শুকনো মসলা ও রান্নার উপকরণ'**
  String get gallerySampleLongCategoryName;

  /// No description provided for @gallerySampleLongDate.
  ///
  /// In bn, this message translates to:
  /// **'সোমবার, ১৯ অক্টোবর ২০২৬ — সপ্তাহের বাজার'**
  String get gallerySampleLongDate;

  /// No description provided for @galleryPersonPickerLabel.
  ///
  /// In bn, this message translates to:
  /// **'কে টাকা দিয়েছে'**
  String get galleryPersonPickerLabel;

  /// No description provided for @monthSwitcherPrevious.
  ///
  /// In bn, this message translates to:
  /// **'আগের মাস'**
  String get monthSwitcherPrevious;

  /// No description provided for @monthSwitcherNext.
  ///
  /// In bn, this message translates to:
  /// **'পরের মাস'**
  String get monthSwitcherNext;

  /// No description provided for @monthSwitcherSelectTitle.
  ///
  /// In bn, this message translates to:
  /// **'মাস নির্বাচন করুন'**
  String get monthSwitcherSelectTitle;

  /// No description provided for @monthSwitcherPreviousYear.
  ///
  /// In bn, this message translates to:
  /// **'আগের বছর'**
  String get monthSwitcherPreviousYear;

  /// No description provided for @monthSwitcherNextYear.
  ///
  /// In bn, this message translates to:
  /// **'পরের বছর'**
  String get monthSwitcherNextYear;

  /// No description provided for @personPickerNone.
  ///
  /// In bn, this message translates to:
  /// **'কেউ না'**
  String get personPickerNone;

  /// No description provided for @totalCalculated.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ × দর থেকে হিসাব করা হয়েছে'**
  String get totalCalculated;

  /// No description provided for @totalEmpty.
  ///
  /// In bn, this message translates to:
  /// **'—'**
  String get totalEmpty;

  /// No description provided for @progressBarPercent.
  ///
  /// In bn, this message translates to:
  /// **'{percent}%'**
  String progressBarPercent(String percent);
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
    'that was used.',
  );
}
