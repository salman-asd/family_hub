import 'package:family_hub/core/utils/quantity.dart';

/// What a [Unit] measures, used by the bazar forms and reports.
extension UnitInfo on Unit {
  bool get isWeight => this == Unit.kg || this == Unit.g;

  bool get isVolume => this == Unit.litre;

  bool get isCount =>
      this == Unit.piece ||
      this == Unit.dozen ||
      this == Unit.packet ||
      this == Unit.cylinder;
}

/// Parses a unit typed in Bangla or English, case-insensitively and trimmed.
///
/// Glass files, spreadsheets and free-text notes use these spellings; anything
/// unrecognised returns `null` so the caller can ask the user to pick a unit
/// instead of silently guessing.
Unit? parseUnit(String raw) {
  final key = raw.trim().toLowerCase();
  return _aliases[key];
}

const Map<String, Unit> _aliases = <String, Unit>{
  // kg
  'কেজি': Unit.kg,
  'kg': Unit.kg,
  'kilo': Unit.kg,
  // gram
  'গ্রাম': Unit.g,
  'g': Unit.g,
  'gm': Unit.g,
  'gram': Unit.g,
  // litre
  'লিটার': Unit.litre,
  'l': Unit.litre,
  'litre': Unit.litre,
  'liter': Unit.litre,
  // piece
  'টা': Unit.piece,
  'টি': Unit.piece,
  'পিস': Unit.piece,
  'piece': Unit.piece,
  'pcs': Unit.piece,
  // dozen
  'ডজন': Unit.dozen,
  'dozen': Unit.dozen,
  // packet
  'প্যাকেট': Unit.packet,
  'packet': Unit.packet,
  'pack': Unit.packet,
  // cylinder
  'সিলিন্ডার': Unit.cylinder,
  'cylinder': Unit.cylinder,
};
