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

  @override
  String get moduleComingSoonTitle => 'Coming soon';

  @override
  String get moduleComingSoonMessage => 'This section is still being built.';

  @override
  String get profileSetupTitle => 'Set up your profile';

  @override
  String get profileSetupMessage => 'Tell your family who you are.';

  @override
  String get familyChoiceTitle => 'Join or create a family';

  @override
  String get familyChoiceMessage =>
      'Create a new family, or join one with an invitation code.';

  @override
  String get pendingTitle => 'Waiting for approval';

  @override
  String get pendingMessage =>
      'A family admin needs to approve your request before you can continue.';

  @override
  String get disabledTitle => 'Access turned off';

  @override
  String get disabledMessage =>
      'Your access to this family has been turned off. Please contact a family admin.';

  @override
  String get placeholderContinueProfile => 'Continue (temporary)';

  @override
  String get placeholderCreateFamily => 'Create a test family (temporary)';

  @override
  String get placeholderApproveMe => 'Pretend I was approved (temporary)';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'The page you opened does not exist.';

  @override
  String get notFoundAction => 'Go to Home';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileNickname => 'Nickname (optional)';

  @override
  String get profileGender => 'Gender (optional)';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get genderNone => 'Prefer not to say';

  @override
  String get profileRelationship => 'Relationship';

  @override
  String get profileAvatar => 'Choose an avatar';

  @override
  String get profileSave => 'Save profile';

  @override
  String get profileSpouse => 'Spouse (optional)';

  @override
  String get profileSpouseNone => 'None';

  @override
  String get relFather => 'Father';

  @override
  String get relMother => 'Mother';

  @override
  String get relSon => 'Son';

  @override
  String get relDaughter => 'Daughter';

  @override
  String get relHusband => 'Husband';

  @override
  String get relWife => 'Wife';

  @override
  String get relHousewife => 'Housewife';

  @override
  String get relDaughterInLaw => 'Daughter-in-law';

  @override
  String get relSonInLaw => 'Son-in-law';

  @override
  String get relOther => 'Other';

  @override
  String get familyCreateAction => 'Create a family';

  @override
  String get familyJoinAction => 'Join with a code';

  @override
  String get familyNameLabel => 'Family name';

  @override
  String get familyCreateSubmit => 'Create family';

  @override
  String get joinCodeLabel => 'Invitation code';

  @override
  String get joinSubmit => 'Request to join';

  @override
  String get joinHint => 'Ask a family admin for the 8-character code.';

  @override
  String get membersTitle => 'Members';

  @override
  String get membersPending => 'Waiting for approval';

  @override
  String get membersActive => 'Active';

  @override
  String get membersDisabled => 'Disabled';

  @override
  String get memberYou => 'You';

  @override
  String get memberApprove => 'Approve';

  @override
  String get memberReject => 'Reject';

  @override
  String get memberDisable => 'Disable';

  @override
  String get memberReenable => 'Re-enable';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleModerator => 'Moderator';

  @override
  String get roleMember => 'Member';

  @override
  String get memberProfileTitle => 'Member profile';

  @override
  String get memberEditProfile => 'Edit my profile';

  @override
  String get memberRoleLabel => 'Role';

  @override
  String get memberStatusLabel => 'Status';

  @override
  String get invitationsTitle => 'Invitations';

  @override
  String get invitationCreate => 'Create invitation code';

  @override
  String get invitationCopy => 'Copy code';

  @override
  String get invitationCopied => 'Code copied';

  @override
  String get invitationExpiresOn => 'Expires';

  @override
  String get invStatusActive => 'Unused';

  @override
  String get invStatusUsed => 'Used';

  @override
  String get invStatusExpired => 'Expired';

  @override
  String get invStatusRevoked => 'Cancelled';

  @override
  String get invitationsEmpty => 'No invitations yet';

  @override
  String get rolesTitle => 'Roles';

  @override
  String get rolesMakeAdmin => 'Make admin';

  @override
  String get rolesTransferTitle => 'Transfer the admin role?';

  @override
  String get rolesTransferMessage => 'You will become a regular member.';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get familySettingsTitle => 'Family settings';

  @override
  String get settingsTimezone => 'Time zone';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsModules => 'Modules';

  @override
  String get settingsSaved => 'Saved';

  @override
  String get famFailureNameRequired => 'Please enter a name.';

  @override
  String get famFailureCodeInvalid =>
      'That code does not look right. Codes have 8 letters and digits.';

  @override
  String get famFailureCodeNotFound => 'No invitation found for that code.';

  @override
  String get famFailureCodeUsed => 'That code was already used.';

  @override
  String get famFailureCodeExpired =>
      'That code has expired. Ask for a new one.';

  @override
  String get famFailureCodeRevoked => 'That code was cancelled.';

  @override
  String get famFailureAlreadyMember => 'You already belong to this family.';

  @override
  String get famFailureLastAdmin =>
      'A family needs at least one admin. Make someone else admin first.';

  @override
  String get famFailureNotAllowed => 'You do not have permission to do that.';

  @override
  String get famFailureProfileRequired => 'Complete your profile first.';

  @override
  String avatarOption(String number) {
    return 'Avatar $number';
  }

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get errorViewTitle => 'Something went wrong';

  @override
  String get loadingSemantics => 'Loading';

  @override
  String progressSemantics(String label, String percent) {
    return '$label, $percent percent complete';
  }

  @override
  String thumbSemantics(String name) {
    return 'Image of $name';
  }

  @override
  String get galleryAvatar => 'Avatar';

  @override
  String get galleryItemThumb => 'Item thumbnail';

  @override
  String get galleryStatusChip => 'Status chip';

  @override
  String get gallerySectionHeader => 'Section header';

  @override
  String get galleryAppCard => 'Card';

  @override
  String get galleryMoneyText => 'Money text';

  @override
  String get galleryProgressRing => 'Progress ring';

  @override
  String get galleryEmptyState => 'Empty state';

  @override
  String get galleryLoadingView => 'Loading view';

  @override
  String get galleryErrorView => 'Error view';

  @override
  String get galleryPillBottomBar => 'Pill navigation bar';

  @override
  String get gallerySampleTitle => 'Sample title';

  @override
  String get gallerySampleMessage =>
      'This is a sample message used to check for overflow.';

  @override
  String get gallerySampleItemName => 'Potato';

  @override
  String get gallerySamplePersonName => 'Karim Uddin';

  @override
  String get syncWaitingTitle => 'Waiting for connection…';

  @override
  String get syncWaitingMessage => 'Check your internet connection and try again. Your data is safe.';

  @override
  String get syncSavedOffline => 'Saved on this device – will sync when online';

  @override
  String syncBannerSyncing(int count) {
    return 'Syncing $count change(s)';
  }

  @override
  String syncBannerOffline(int count) {
    return 'Offline – $count change(s) waiting';
  }

  @override
  String get gallerySyncBanner => 'Sync banner';

  @override
  String get famFailureAlreadyInFamily => 'You already belong to a family. Leave it first.';

  @override
  String get familyLeave => 'Leave family';

  @override
  String get familyLeaveConfirmTitle => 'Leave this family?';

  @override
  String get familyLeaveConfirmBody => 'Your past activity stays in the family\'s history. Afterwards you can create or join a family again.';

  @override
  String get familyLeaveLastAdminReason => 'You are the only admin. Make someone else an admin before leaving.';

  @override
  String get pendingCancelRequest => 'Cancel request';

  @override
  String get invitationRevoke => 'Revoke code';

  @override
  String get invitationRevokeConfirmTitle => 'Revoke this code?';

  @override
  String get invitationRevokeConfirmBody => 'Nobody will be able to join with this code any more.';
}
