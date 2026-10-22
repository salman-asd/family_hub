import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/role.dart';

/// Localized role names.  Lives in `core/` (not in a screen) so that no widget
/// has to name a role to print it: the UI asks `ref.can(...)` for decisions
/// (H7) and this extension only for words.
extension RoleLabels on AppLocalizations {
  String roleLabel(Role r) => switch (r) {
    Role.admin => roleAdmin,
    Role.moderator => roleModerator,
    Role.member => roleMember,
  };
}
