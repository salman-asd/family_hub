import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/quantity.dart';

/// Localized unit names for the bazar forms and reports.
///
/// Lives in `core/` next to `role_labels.dart` so no widget has to print a raw
/// enum name (CLAUDE.md rule 18).
extension UnitLabels on AppLocalizations {
  String unitLabel(Unit unit) => switch (unit) {
    Unit.kg => unitKg,
    Unit.g => unitG,
    Unit.litre => unitLitre,
    Unit.piece => unitPiece,
    Unit.dozen => unitDozen,
    Unit.packet => unitPacket,
    Unit.cylinder => unitCylinder,
  };
}
