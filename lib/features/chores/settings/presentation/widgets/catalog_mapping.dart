import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/shared/widgets/catalog_editor.dart';

/// Conversions between the three settings catalogs and the generic rows of
/// `CatalogEditor` (P3-17). Pure functions, so they are unit-testable.
///
/// A row that came back from the editor is matched to its original by id, so
/// the fields the editor does not show (a group's colour and icon, a preset's
/// minutes, every `builtIn` flag) are never lost.
abstract final class CatalogMapping {
  /// `custom_1`, `custom_2`, ...: the smallest number not in [used]. Never
  /// built from the clock, so the id is predictable and fits the validator's
  /// `[a-z0-9_]{1,24}` rule.
  static String nextCustomId(Iterable<String> used) {
    final taken = used.toSet();
    var n = 1;
    while (taken.contains('custom_$n')) {
      n++;
    }
    return 'custom_$n';
  }

  // ── Groups ─────────────────────────────────────────────────────────────────

  static CatalogEntry groupEntry(ChoreGroup g) => CatalogEntry(
    id: g.id,
    labelBn: g.nameBn,
    labelEn: g.nameEn,
    active: g.active,
    builtIn: g.builtIn,
    extra: g,
  );

  /// The groups for the rows in their new order; `sortOrder` follows position.
  static List<ChoreGroup> groupsFrom(
    List<CatalogEntry> rows,
    List<ChoreGroup> originals,
  ) {
    final byId = <String, ChoreGroup>{for (final g in originals) g.id: g};
    return <ChoreGroup>[
      for (var i = 0; i < rows.length; i++)
        _group(rows[i], byId[rows[i].id]).copyWith(sortOrder: i),
    ];
  }

  static ChoreGroup _group(CatalogEntry row, ChoreGroup? original) {
    final extra = row.extra;
    final base = extra is ChoreGroup ? extra : original;
    if (base == null) {
      return ChoreGroup(
        id: row.id,
        nameBn: row.labelBn,
        nameEn: row.labelEn,
        active: row.active,
      );
    }
    return base.copyWith(
      nameBn: row.labelBn,
      nameEn: row.labelEn,
      active: row.active,
    );
  }

  // ── Due-time presets ───────────────────────────────────────────────────────

  static CatalogEntry presetEntry(DueTimePreset p, String time) =>
      CatalogEntry(
        id: p.id,
        labelBn: p.labelBn,
        labelEn: p.labelEn,
        active: p.active,
        builtIn: p.builtIn,
        detail: time,
        extra: p,
      );

  static List<DueTimePreset> presetsFrom(
    List<CatalogEntry> rows,
    List<DueTimePreset> originals,
  ) {
    final byId = <String, DueTimePreset>{for (final p in originals) p.id: p};
    return <DueTimePreset>[
      for (final row in rows)
        _preset(row, byId[row.id]),
    ];
  }

  static DueTimePreset _preset(CatalogEntry row, DueTimePreset? original) {
    final extra = row.extra;
    final base = extra is DueTimePreset ? extra : original;
    if (base == null) {
      // A row added by the generic dialog carries no time; 09:00 is only a
      // placeholder the validator accepts, the preset dialog always sets one.
      return DueTimePreset(
        id: row.id,
        labelBn: row.labelBn,
        labelEn: row.labelEn,
        minutes: 540,
        active: row.active,
      );
    }
    return base.copyWith(
      labelBn: row.labelBn,
      labelEn: row.labelEn,
      active: row.active,
    );
  }

  // ── Absence reasons ────────────────────────────────────────────────────────

  static CatalogEntry reasonEntry(AbsenceReason r) => CatalogEntry(
    id: r.id,
    labelBn: r.labelBn,
    labelEn: r.labelEn,
    active: r.active,
    builtIn: r.builtIn,
  );

  static List<AbsenceReason> reasonsFrom(
    List<CatalogEntry> rows,
    List<AbsenceReason> originals,
  ) {
    final byId = <String, AbsenceReason>{for (final r in originals) r.id: r};
    return <AbsenceReason>[
      for (final row in rows)
        if (byId[row.id] case final original?)
          original.copyWith(
            labelBn: row.labelBn,
            labelEn: row.labelEn,
            active: row.active,
          )
        else
          AbsenceReason(
            id: row.id,
            labelBn: row.labelBn,
            labelEn: row.labelEn,
            active: row.active,
          ),
    ];
  }
}
