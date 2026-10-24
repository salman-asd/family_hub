import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';

/// The localized message for [field] in a form's `fieldErrors`, or `null`.
String? fieldErrorText(
  AppLocalizations l10n,
  Map<String, String> errors,
  String field,
) {
  final code = errors[field];
  return code == null ? null : l10n.bazarFailureMessage(Validation(field, code));
}
