import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:flutter/widgets.dart';

/// One tile on the Bazar home screen.
///
/// Later Phase 2 steps append an entry; the home screen renders this list and
/// hides a tile when the viewer lacks [requires] (H7, never a role test).
class BazarEntry {
  const BazarEntry({
    required this.id,
    required this.icon,
    required this.label,
    required this.route,
    this.requires,
  });

  /// Stable id, used by tests and analytics; never shown.
  final String id;

  final IconData icon;

  /// Localized label, resolved by the screen so no copy lives in this file.
  final String Function(AppLocalizations) label;

  /// Route inside [AppRoutes.bazar].
  final String route;

  /// Permission the viewer needs to see this tile; `null` = everybody.
  final Permission? requires;
}

/// The Bazar home tiles.  Empty in P2-01; every later step appends one.
final List<BazarEntry> bazarEntries = <BazarEntry>[];
