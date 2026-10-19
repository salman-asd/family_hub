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

  @override
  String get moduleComingSoonTitle => 'শীঘ্রই আসছে';

  @override
  String get moduleComingSoonMessage => 'এই অংশটি এখনো তৈরি হচ্ছে।';

  @override
  String get profileSetupTitle => 'আপনার প্রোফাইল তৈরি করুন';

  @override
  String get profileSetupMessage => 'পরিবারকে জানান আপনি কে।';

  @override
  String get familyChoiceTitle => 'পরিবারে যোগ দিন বা নতুন তৈরি করুন';

  @override
  String get familyChoiceMessage =>
      'নতুন পরিবার তৈরি করুন, অথবা আমন্ত্রণ কোড দিয়ে যোগ দিন।';

  @override
  String get pendingTitle => 'অনুমোদনের অপেক্ষায়';

  @override
  String get pendingMessage =>
      'চালিয়ে যেতে পরিবারের অ্যাডমিনকে আপনার অনুরোধ অনুমোদন করতে হবে।';

  @override
  String get disabledTitle => 'প্রবেশ বন্ধ আছে';

  @override
  String get disabledMessage =>
      'এই পরিবারে আপনার প্রবেশ বন্ধ করা হয়েছে। অনুগ্রহ করে অ্যাডমিনের সাথে যোগাযোগ করুন।';

  @override
  String get placeholderContinueProfile => 'চালিয়ে যান (অস্থায়ী)';

  @override
  String get placeholderCreateFamily =>
      'পরীক্ষামূলক পরিবার তৈরি করুন (অস্থায়ী)';

  @override
  String get placeholderApproveMe => 'অনুমোদিত ধরে নিন (অস্থায়ী)';

  @override
  String get notFoundTitle => 'পাতাটি পাওয়া যায়নি';

  @override
  String get notFoundMessage => 'আপনি যে পাতাটি খুলেছেন সেটি নেই।';

  @override
  String get notFoundAction => 'হোমে যান';

  @override
  String get profileFullName => 'পুরো নাম';

  @override
  String get profileNickname => 'ডাকনাম (ঐচ্ছিক)';

  @override
  String get profileGender => 'লিঙ্গ (ঐচ্ছিক)';

  @override
  String get genderMale => 'পুরুষ';

  @override
  String get genderFemale => 'নারী';

  @override
  String get genderOther => 'অন্যান্য';

  @override
  String get genderNone => 'বলতে চাই না';

  @override
  String get profileRelationship => 'সম্পর্ক';

  @override
  String get profileAvatar => 'একটি অ্যাভাটার বেছে নিন';

  @override
  String get profileSave => 'প্রোফাইল সংরক্ষণ করুন';

  @override
  String get profileSpouse => 'স্বামী/স্ত্রী (ঐচ্ছিক)';

  @override
  String get profileSpouseNone => 'কেউ নয়';

  @override
  String get relFather => 'বাবা';

  @override
  String get relMother => 'মা';

  @override
  String get relSon => 'ছেলে';

  @override
  String get relDaughter => 'মেয়ে';

  @override
  String get relHusband => 'স্বামী';

  @override
  String get relWife => 'স্ত্রী';

  @override
  String get relHousewife => 'গৃহিণী';

  @override
  String get relDaughterInLaw => 'পুত্রবধূ';

  @override
  String get relSonInLaw => 'জামাই';

  @override
  String get relOther => 'অন্যান্য';

  @override
  String get familyCreateAction => 'নতুন পরিবার তৈরি করুন';

  @override
  String get familyJoinAction => 'কোড দিয়ে যোগ দিন';

  @override
  String get familyNameLabel => 'পরিবারের নাম';

  @override
  String get familyCreateSubmit => 'পরিবার তৈরি করুন';

  @override
  String get joinCodeLabel => 'আমন্ত্রণ কোড';

  @override
  String get joinSubmit => 'যোগদানের অনুরোধ করুন';

  @override
  String get joinHint => 'পরিবারের অ্যাডমিনের কাছ থেকে ৮ অক্ষরের কোড নিন।';

  @override
  String get membersTitle => 'সদস্য';

  @override
  String get membersPending => 'অনুমোদনের অপেক্ষায়';

  @override
  String get membersActive => 'সক্রিয়';

  @override
  String get membersDisabled => 'নিষ্ক্রিয়';

  @override
  String get memberYou => 'আপনি';

  @override
  String get memberApprove => 'অনুমোদন';

  @override
  String get memberReject => 'প্রত্যাখ্যান';

  @override
  String get memberDisable => 'নিষ্ক্রিয় করুন';

  @override
  String get memberReenable => 'আবার সক্রিয় করুন';

  @override
  String get roleAdmin => 'অ্যাডমিন';

  @override
  String get roleModerator => 'মডারেটর';

  @override
  String get roleMember => 'সদস্য';

  @override
  String get memberProfileTitle => 'সদস্যের প্রোফাইল';

  @override
  String get memberEditProfile => 'আমার প্রোফাইল সম্পাদনা';

  @override
  String get memberRoleLabel => 'ভূমিকা';

  @override
  String get memberStatusLabel => 'অবস্থা';

  @override
  String get invitationsTitle => 'আমন্ত্রণ';

  @override
  String get invitationCreate => 'আমন্ত্রণ কোড তৈরি করুন';

  @override
  String get invitationCopy => 'কোড কপি করুন';

  @override
  String get invitationCopied => 'কোড কপি হয়েছে';

  @override
  String get invitationExpiresOn => 'মেয়াদ শেষ';

  @override
  String get invStatusActive => 'অব্যবহৃত';

  @override
  String get invStatusUsed => 'ব্যবহৃত';

  @override
  String get invStatusExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String get invStatusRevoked => 'বাতিল';

  @override
  String get invitationsEmpty => 'এখনো কোনো আমন্ত্রণ নেই';

  @override
  String get rolesTitle => 'ভূমিকা';

  @override
  String get rolesMakeAdmin => 'অ্যাডমিন বানান';

  @override
  String get rolesTransferTitle => 'অ্যাডমিনের দায়িত্ব হস্তান্তর করবেন?';

  @override
  String get rolesTransferMessage => 'আপনি সাধারণ সদস্য হয়ে যাবেন।';

  @override
  String get actionConfirm => 'নিশ্চিত করুন';

  @override
  String get familySettingsTitle => 'পরিবারের সেটিংস';

  @override
  String get settingsTimezone => 'সময় অঞ্চল';

  @override
  String get settingsCurrency => 'মুদ্রা';

  @override
  String get settingsModules => 'মডিউল';

  @override
  String get settingsSaved => 'সংরক্ষিত হয়েছে';

  @override
  String get famFailureNameRequired => 'একটি নাম লিখুন।';

  @override
  String get famFailureCodeInvalid =>
      'কোডটি সঠিক নয়। কোডে ৮টি অক্ষর ও সংখ্যা থাকে।';

  @override
  String get famFailureCodeNotFound => 'এই কোডে কোনো আমন্ত্রণ পাওয়া যায়নি।';

  @override
  String get famFailureCodeUsed => 'এই কোডটি আগেই ব্যবহার করা হয়েছে।';

  @override
  String get famFailureCodeExpired => 'কোডটির মেয়াদ শেষ। নতুন কোড চান।';

  @override
  String get famFailureCodeRevoked => 'কোডটি বাতিল করা হয়েছে।';

  @override
  String get famFailureAlreadyMember => 'আপনি ইতিমধ্যে এই পরিবারে আছেন।';

  @override
  String get famFailureLastAdmin =>
      'পরিবারে অন্তত একজন অ্যাডমিন থাকতে হবে। আগে অন্য কাউকে অ্যাডমিন বানান।';

  @override
  String get famFailureTooManyAdmins =>
      'একটি পরিবারে সর্বোচ্চ তিনজন অ্যাডমিন থাকতে পারে।';

  @override
  String get famFailureNotAllowed => 'এটি করার অনুমতি আপনার নেই।';

  @override
  String get famFailureProfileRequired => 'আগে আপনার প্রোফাইল সম্পূর্ণ করুন।';

  @override
  String avatarOption(String number) {
    return 'অ্যাভাটার $number';
  }

  @override
  String get statusScheduled => 'সময় নির্ধারিত';

  @override
  String get statusInProgress => 'চলছে';

  @override
  String get statusCompleted => 'সম্পন্ন';

  @override
  String get statusVerified => 'যাচাইকৃত';

  @override
  String get statusOverdue => 'সময় পার হয়েছে';

  @override
  String get commonSeeAll => 'সব দেখুন';

  @override
  String get errorViewTitle => 'কিছু ভুল হয়েছে';

  @override
  String get loadingSemantics => 'লোড হচ্ছে';

  @override
  String progressSemantics(String label, String percent) {
    return '$label, $percent শতাংশ সম্পন্ন';
  }

  @override
  String thumbSemantics(String name) {
    return '$name ছবি';
  }

  @override
  String get galleryAvatar => 'অ্যাভাটার';

  @override
  String get galleryItemThumb => 'জিনিসের ছবি';

  @override
  String get galleryStatusChip => 'অবস্থার চিপ';

  @override
  String get gallerySectionHeader => 'সেকশন হেডার';

  @override
  String get galleryAppCard => 'কার্ড';

  @override
  String get galleryMoneyText => 'টাকার লেখা';

  @override
  String get galleryProgressRing => 'প্রগ্রেস রিং';

  @override
  String get galleryEmptyState => 'খালি অবস্থা';

  @override
  String get galleryLoadingView => 'লোডিং দৃশ্য';

  @override
  String get galleryErrorView => 'ত্রুটির দৃশ্য';

  @override
  String get galleryPillBottomBar => 'পিল নেভিগেশন বার';

  @override
  String get gallerySampleTitle => 'নমুনা শিরোনাম';

  @override
  String get gallerySampleMessage =>
      'এটি একটি নমুনা বার্তা যা ওভারফ্লো যাচাই করে।';

  @override
  String get gallerySampleItemName => 'আলু';

  @override
  String get gallerySamplePersonName => 'করিম উদ্দিন';

  @override
  String get syncWaitingTitle => 'সংযোগের অপেক্ষায়…';

  @override
  String get syncWaitingMessage =>
      'ইন্টারনেট সংযোগ আছে কিনা দেখুন, তারপর আবার চেষ্টা করুন। আপনার তথ্য নিরাপদ আছে।';

  @override
  String get syncSavedOffline =>
      'এই ডিভাইসে সংরক্ষিত হয়েছে — অনলাইনে এলে সিঙ্ক হবে';

  @override
  String syncBannerSyncing(int count) {
    return '$countটি পরিবর্তন সিঙ্ক হচ্ছে';
  }

  @override
  String syncBannerOffline(int count) {
    return 'অফলাইন — $countটি পরিবর্তন অপেক্ষায়';
  }

  @override
  String get gallerySyncBanner => 'সিঙ্ক ব্যানার';

  @override
  String get famFailureAlreadyInFamily =>
      'আপনি ইতিমধ্যে একটি পরিবারে আছেন। আগে সেটি ছেড়ে দিন।';

  @override
  String get familyLeave => 'পরিবার ছেড়ে যান';

  @override
  String get familyLeaveConfirmTitle => 'পরিবার ছেড়ে যাবেন?';

  @override
  String get familyLeaveConfirmBody =>
      'আপনার আগের কাজ ও হিসাবের ইতিহাস পরিবারে থেকে যাবে। পরে আপনি নতুন পরিবার খুলতে বা অন্য পরিবারে যোগ দিতে পারবেন।';

  @override
  String get familyLeaveLastAdminReason =>
      'আপনিই একমাত্র অ্যাডমিন। ছেড়ে যাওয়ার আগে আরেকজনকে অ্যাডমিন করুন।';

  @override
  String get pendingCancelRequest => 'অনুরোধ বাতিল করুন';

  @override
  String get invitationRevoke => 'কোড বাতিল করুন';

  @override
  String get invitationRevokeConfirmTitle => 'কোডটি বাতিল করবেন?';

  @override
  String get invitationRevokeConfirmBody =>
      'এই কোড দিয়ে আর কেউ যোগ দিতে পারবে না।';
}
