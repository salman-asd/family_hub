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
  String get bazarHomeEmptyTitle => 'Bazar is empty';

  @override
  String get bazarHomeEmptyMessage =>
      'Expenses, shopping lists and accounts will be added here step by step.';

  @override
  String get bazarCatalogSetupTitle => 'Set up the starter catalog';

  @override
  String get bazarCatalogSetupMessage =>
      'Add 11 categories and 54 common items to get started. You can edit, add or hide them later.';

  @override
  String get bazarCatalogSetupAction => 'Set up catalog';

  @override
  String get bazarCatalogSetupBusy => 'Setting up the catalog…';

  @override
  String get bazarCatalogAskAdminTitle => 'Catalog not set up';

  @override
  String get bazarCatalogAskAdminMessage =>
      'Ask an admin to set up the catalog.';

  @override
  String get bazarSettingsTitle => 'Bazar settings';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitLitre => 'litre';

  @override
  String get unitPiece => 'pcs';

  @override
  String get unitDozen => 'dozen';

  @override
  String get unitPacket => 'packet';

  @override
  String get unitCylinder => 'cylinder';

  @override
  String get bazarFundingFund => 'family fund';

  @override
  String get bazarFundingMember => 'member paid';

  @override
  String get bazarAdvancePending => 'pending';

  @override
  String get bazarAdvancePartial => 'partly settled';

  @override
  String get bazarAdvanceSettled => 'settled';

  @override
  String get bazarAdvanceVoided => 'voided';

  @override
  String get bazarErrRequired => 'Please fill in this field.';

  @override
  String get bazarErrTooLong => 'This text is too long.';

  @override
  String get bazarErrInvalidAmount => 'Enter a valid amount.';

  @override
  String get bazarErrAmountNotPositive => 'The amount must be more than zero.';

  @override
  String get bazarErrFutureDate => 'The date cannot be in the future.';

  @override
  String get bazarErrQtyUnitRequired => 'Enter both a quantity and a unit.';

  @override
  String get bazarErrMemberRequired => 'Choose the member this belongs to.';

  @override
  String get bazarErrCategoryRequired => 'Choose a category.';

  @override
  String get bazarErrItemNameRequired => 'Enter the item name.';

  @override
  String get bazarErrTooManyLines => 'There are too many lines; remove some.';

  @override
  String get bazarErrInvalidMonth => 'Choose a valid month.';

  @override
  String get bazarErrInvalidRange =>
      'The end date must be after the start date.';

  @override
  String get bazarErrNegative => 'The amount cannot be below zero.';

  @override
  String get bazarErrTooManyDecimals => 'Use at most two decimal places.';

  @override
  String get bazarErrTooLarge => 'That amount is too large.';

  @override
  String get bazarErrMonthLocked =>
      'This month is closed. Ask an admin to reopen it.';

  @override
  String get bazarErrAdvanceSettled =>
      'This advance has already been partly or fully settled.';

  @override
  String get bazarErrOverpayment =>
      'The amount is more than what is still owed.';

  @override
  String get bazarErrAlreadyClosed => 'This month is already closed.';

  @override
  String get bazarErrNotClosed => 'This month is not closed.';

  @override
  String get bazarErrReopenNoteRequired =>
      'Write why the month is being reopened.';

  @override
  String get bazarErrCatalogNotEmpty =>
      'The catalog still has items; archive them first.';

  @override
  String get bazarErrDuplicateItem =>
      'A similar expense was just added. Check it before saving again.';

  @override
  String get bazarErrImportAlreadyUndone =>
      'This import has already been undone.';

  @override
  String get bazarErrImportHasLockedMonth =>
      'The file has rows in a closed month.';

  @override
  String get bazarErrConcurrentEdit =>
      'Somebody else changed this first. Reload and try again.';

  @override
  String get bazarErrNotFound =>
      'That record no longer exists. Refresh and try again.';

  @override
  String get bazarErrNotAllowed =>
      'Only the Household Manager or Admin can do this.';

  @override
  String get bazarErrUnknown => 'Something went wrong. Please try again.';

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
  String get roleModerator => 'Household Manager';

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
  String get famFailureTooManyAdmins =>
      'A family can have at most three admins.';

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
  String get syncWaitingMessage =>
      'Check your internet connection and try again. Your data is safe.';

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
  String get famFailureAlreadyInFamily =>
      'You already belong to a family. Leave it first.';

  @override
  String get familyLeave => 'Leave family';

  @override
  String get familyLeaveConfirmTitle => 'Leave this family?';

  @override
  String get familyLeaveConfirmBody =>
      'Your past activity stays in the family\'s history. Afterwards you can create or join a family again.';

  @override
  String get familyLeaveLastAdminReason =>
      'You are the only admin. Make someone else an admin before leaving.';

  @override
  String get pendingCancelRequest => 'Cancel request';

  @override
  String get invitationRevoke => 'Revoke code';

  @override
  String get invitationRevokeConfirmTitle => 'Revoke this code?';

  @override
  String get invitationRevokeConfirmBody =>
      'Nobody will be able to join with this code any more.';

  @override
  String get securityTitle => 'Security';

  @override
  String get securityChangePassword => 'Change password';

  @override
  String get securityCurrentPassword => 'Current password';

  @override
  String get securityNewPassword => 'New password';

  @override
  String get securityPasswordChanged => 'Password changed.';

  @override
  String get securityPasswordSame =>
      'The new password must differ from the current one.';

  @override
  String get securityCurrentPasswordRequired => 'Enter your current password.';

  @override
  String get securityCurrentPasswordWrong =>
      'The current password is not correct.';

  @override
  String get securityDeleteTitle => 'Delete my account';

  @override
  String get securityDeleteBody =>
      'You leave your family and your sign-in is removed. Your name stays on past records so the family history stays complete.';

  @override
  String get securityDeletePending =>
      'Deleting was not finished. Enter your password to finish.';

  @override
  String get securityDeleteAction => 'Delete account';

  @override
  String get securityDeleteFinish => 'Finish deleting';

  @override
  String get securityDeleteConfirmTitle => 'Delete your account?';

  @override
  String get securityDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get accountDeleteLastAdminHasMembers =>
      'You are the only admin and others are still in the family. Transfer the admin role first.';

  @override
  String get relationshipsTitle => 'Relationships';

  @override
  String get relationshipsHint =>
      'Built-in entries are locked. You can add, rename and disable your own.';

  @override
  String get relationshipsAdd => 'Add relationship';

  @override
  String get relationshipsLabelBn => 'Name in Bangla';

  @override
  String get relationshipsLabelEn => 'Name in English';

  @override
  String get relationshipsSpouseRelevant => 'Offer the spouse picker';

  @override
  String get relationshipsBuiltIn => 'Built in';

  @override
  String get relationshipsActive => 'In use';

  @override
  String get relationshipsDisabled => 'Disabled';

  @override
  String get relationshipsEnable => 'Enable';

  @override
  String get relationshipsDisable => 'Disable';

  @override
  String get relationshipsFailureLabel =>
      'Enter a name (at most 40 characters).';

  @override
  String get relationshipsFailureTooMany => 'The list is full.';

  @override
  String get relationshipsFailureBuiltIn =>
      'Built-in entries cannot be changed.';

  @override
  String activityFamilyCreated(String familyName) {
    return 'Family “$familyName” was created';
  }

  @override
  String get activityFamilyUpdated => 'Family settings were updated';

  @override
  String activityMemberRequested(String memberName) {
    return '$memberName asked to join';
  }

  @override
  String activityMemberApproved(String memberName) {
    return '$memberName was approved';
  }

  @override
  String activityMemberRejected(String memberName) {
    return '$memberName was not accepted';
  }

  @override
  String activityMemberDisabled(String memberName) {
    return '$memberName was disabled';
  }

  @override
  String activityMemberRoleChanged(String memberName, String newRole) {
    return '$memberName is now $newRole';
  }

  @override
  String activityAdminTransferred(String memberName) {
    return 'Admin role moved to $memberName';
  }

  @override
  String activityMemberLeft(String memberName) {
    return '$memberName left the family';
  }

  @override
  String activityMemberCancelled(String memberName) {
    return '$memberName withdrew the request';
  }

  @override
  String activityInvitationCreated(String code) {
    return 'Invitation $code was created';
  }

  @override
  String activityInvitationRevoked(String code) {
    return 'Invitation $code was revoked';
  }

  @override
  String activityBazarCatalogSeeded(String categories, String items) {
    return 'Bazar catalog started with $categories categories and $items items';
  }

  @override
  String activityBazarCategoryCreated(String name) {
    return 'Category “$name” was added';
  }

  @override
  String activityBazarCategoryUpdated(String name) {
    return 'Category “$name” was updated';
  }

  @override
  String activityBazarCategoryDeactivated(String name) {
    return 'Category “$name” was archived';
  }

  @override
  String activityBazarItemCreated(String name) {
    return 'Item “$name” was added';
  }

  @override
  String activityBazarItemUpdated(String name) {
    return 'Item “$name” was updated';
  }

  @override
  String activityBazarItemDeactivated(String name) {
    return 'Item “$name” was archived';
  }

  @override
  String activityBazarExpenseCreated(
    String item,
    String amount,
    String funding,
  ) {
    return 'Bought $item for $amount ($funding)';
  }

  @override
  String activityBazarExpenseUpdated(String item, String fields) {
    return '$item was edited ($fields)';
  }

  @override
  String activityBazarExpenseDeleted(String item, String amount) {
    return '$item was deleted ($amount)';
  }

  @override
  String activityBazarExpenseRestored(String item, String amount) {
    return '$item was restored ($amount)';
  }

  @override
  String activityBazarTripCreated(String lines, String amount) {
    return 'Bazar trip with $lines items for $amount was saved';
  }

  @override
  String activityBazarBudgetSaved(String month, String amount) {
    return 'Budget for $month set to $amount';
  }

  @override
  String get activityBazarSettingsUpdated => 'Bazar settings were updated';

  @override
  String activityBazarContributionPlanSet(
    String month,
    String member,
    String amount,
  ) {
    return '$member\'s contribution for $month set to $amount';
  }

  @override
  String activityBazarContributionRecorded(
    String month,
    String member,
    String amount,
  ) {
    return '$member\'s contribution of $amount for $month was recorded';
  }

  @override
  String activityBazarContributionVoided(
    String month,
    String member,
    String amount,
  ) {
    return '$member\'s contribution of $amount for $month was voided';
  }

  @override
  String activityBazarContributionRequested(
    String month,
    String member,
    String amount,
  ) {
    return '$member offered $amount for $month';
  }

  @override
  String activityBazarContributionRequestEdited(
    String month,
    String member,
    String amount,
  ) {
    return '$member edited the offer of $amount for $month';
  }

  @override
  String activityBazarContributionRequestCancelled(
    String month,
    String member,
    String amount,
  ) {
    return '$member withdrew the offer of $amount for $month';
  }

  @override
  String activityBazarContributionApproved(
    String month,
    String member,
    String amount,
  ) {
    return '$member\'s contribution of $amount for $month was approved';
  }

  @override
  String activityBazarContributionRejected(
    String month,
    String member,
    String amount,
    String reason,
  ) {
    return '$member\'s contribution of $amount for $month was rejected ($reason)';
  }

  @override
  String activityBazarContributionChangeRequested(
    String month,
    String member,
    String amount,
    String old,
  ) {
    return '$member asked to change the contribution for $month from $old to $amount';
  }

  @override
  String activityBazarContributionChangeApproved(
    String month,
    String member,
    String amount,
    String old,
  ) {
    return '$member\'s change for $month from $old to $amount was approved';
  }

  @override
  String activityBazarContributionChangeRejected(
    String month,
    String member,
    String amount,
    String old,
  ) {
    return '$member\'s change for $month from $old to $amount was rejected';
  }

  @override
  String activityBazarOpeningBalanceSet(String month, String amount) {
    return 'Opening balance for $month is $amount';
  }

  @override
  String activityBazarAdvanceSettled(
    String member,
    String amount,
    String status,
  ) {
    return '$member\'s advance was settled by $amount ($status)';
  }

  @override
  String activityBazarMonthClosed(String month, String balance) {
    return '$month was closed with a balance of $balance';
  }

  @override
  String activityBazarMonthReopened(String month, String note) {
    return '$month was reopened ($note)';
  }

  @override
  String activityBazarImportCompleted(String rows, String amount) {
    return 'Import finished: $rows rows for $amount';
  }

  @override
  String activityBazarImportUndone(String rows, String amount) {
    return 'Import undone: $rows rows for $amount';
  }

  @override
  String get activityUnknown => 'Something changed';

  @override
  String get galleryMonthSwitcher => 'Month switcher';

  @override
  String get galleryAmountField => 'Amount field';

  @override
  String get galleryTotalDisplay => 'Total display';

  @override
  String get galleryProgressBarStatus => 'Limit progress bar';

  @override
  String get galleryDaySectionHeader => 'Day header';

  @override
  String get galleryPersonPicker => 'Person picker';

  @override
  String get galleryCategoryBadge => 'Category badge';

  @override
  String get monthSwitcherPrevious => 'Previous month';

  @override
  String get monthSwitcherNext => 'Next month';

  @override
  String get monthSwitcherPick => 'Choose a month';

  @override
  String get monthPickerPreviousYear => 'Previous year';

  @override
  String get monthPickerNextYear => 'Next year';

  @override
  String get totalDisplayCalculated => 'Calculated from quantity × price';

  @override
  String get totalDisplayEmpty => 'No total yet';

  @override
  String get progressLevelOk => 'On track';

  @override
  String get progressLevelWarning => 'Nearing the limit';

  @override
  String get progressLevelExceeded => 'Over the limit';

  @override
  String get progressLevelNoLimit => 'No limit set';

  @override
  String progressBarSemantics(String label, String percent, String level) {
    return '$label: $percent percent, $level';
  }

  @override
  String get personPickerNone => 'No one';
}
