import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A self-contained area of the app (roadmap Section 10): Chores, Bazar, and
/// whatever comes later (Events, ...).
///
/// A module is switched on or off per family through [ModuleFlags]; a disabled
/// module disappears from the navigation bar and its routes become
/// unreachable.  Adding a module means implementing this class and adding it to
/// the registry — no screen outside the module changes.
abstract class FamilyModule {
  const FamilyModule();

  /// Stable id used in `settings/modules` and in permissions.
  String get id;

  /// Display names (also usable where no `BuildContext` exists).
  String get nameBn;
  String get nameEn;

  /// Localized tab label.
  String label(AppLocalizations l10n);

  /// Icon of the tab; [selectedIcon] defaults to [icon].
  IconData get icon;
  IconData get selectedIcon => icon;

  /// The module's first path, e.g. `/chores`.  Every route below sits under it;
  /// the router redirects it to `/home` while the module is off.
  String get basePath;

  /// Routes of this module's navigation branch.
  List<RouteBase> get routes;

  /// Dashboard cards the module contributes (Step 27).
  List<WidgetBuilder> get dashboardCards => const [];

  /// Ids of report views the module contributes (Step 18).
  List<String> get reports => const [];

  /// Permission needed to see the module's tab; `null` = every member.  The
  /// shell hides the tab (and redirects its paths) while the signed-in member
  /// lacks it (`visibleModulesProvider`).
  Permission? get requiredPermission => null;
}
