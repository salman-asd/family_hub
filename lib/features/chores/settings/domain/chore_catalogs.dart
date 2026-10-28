import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/default_chore_settings.dart';

/// Lookups over the catalogs of one [ChoreSettings] (road map 3.2).
///
/// TOLERANT by design: a template may reference a group that was deactivated,
/// renamed or removed, and a document may hold an id this build does not know.
/// Every lookup therefore returns a usable value instead of throwing:
/// * an unknown group id resolves to the `other` group (or the first group);
/// * an unknown preset/reason id resolves to `null`, and the caller shows the
///   stored label it already has.
///
/// Screens read the lists through [activeGroups] / [activePresets] /
/// [activeAbsenceReasons], which are sorted by `sortOrder` (then by name, so
/// two rows with the same order are still stable).
final class ChoreCatalogs {
  const ChoreCatalogs(this.settings);

  factory ChoreCatalogs.of(ChoreSettings settings) => ChoreCatalogs(settings);

  final ChoreSettings settings;

  // ── Groups ──────────────────────────────────────────────────────────────────

  /// Every group, active or not, in display order.
  List<ChoreGroup> get groups => _sortedGroups(settings.groups);

  /// Only the groups a new chore may choose.
  List<ChoreGroup> get activeGroups =>
      groups.where((group) => group.active).toList(growable: false);

  /// The group with [id], active or not; `null` when the id is unknown.
  ChoreGroup? groupOrNull(String? id) {
    if (id == null) return null;
    for (final group in groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  /// The group with [id] for DISPLAY: falls back to the `other` group, then to
  /// the first group, so a chore is never shown without a colour or a name.
  ChoreGroup groupOf(String? id) {
    final found = groupOrNull(id);
    if (found != null) return found;
    final other = groupOrNull(fallbackGroupId);
    if (other != null) return other;
    if (groups.isNotEmpty) return groups.first;
    // Only reachable with a completely empty catalog (the validator forbids
    // saving one): the built-in fallback keeps the UI alive.
    return defaultGroups.last;
  }

  // ── Due-time presets ────────────────────────────────────────────────────────

  List<DueTimePreset> get presets => _sortedPresets(settings.dueTimePresets);

  List<DueTimePreset> get activePresets =>
      presets.where((preset) => preset.active).toList(growable: false);

  DueTimePreset? presetOf(String? id) {
    if (id == null) return null;
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  // ── Absence reasons ─────────────────────────────────────────────────────────

  List<AbsenceReason> get absenceReasons =>
      _sortedReasons(settings.absenceReasons);

  List<AbsenceReason> get activeAbsenceReasons =>
      absenceReasons.where((reason) => reason.active).toList(growable: false);

  AbsenceReason? reasonOf(String? id) {
    if (id == null) return null;
    for (final reason in absenceReasons) {
      if (reason.id == id) return reason;
    }
    return null;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static List<ChoreGroup> _sortedGroups(List<ChoreGroup> input) {
    final copy = <ChoreGroup>[...input];
    copy.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.nameBn.compareTo(b.nameBn);
    });
    return List<ChoreGroup>.unmodifiable(copy);
  }

  /// Presets are ordered by TIME, not by list position: "morning, noon,
  /// evening" must read in clock order even after an edit.
  static List<DueTimePreset> _sortedPresets(List<DueTimePreset> input) {
    final copy = <DueTimePreset>[...input];
    copy.sort((a, b) {
      final byMinutes = a.minutes.compareTo(b.minutes);
      return byMinutes != 0 ? byMinutes : a.labelBn.compareTo(b.labelBn);
    });
    return List<DueTimePreset>.unmodifiable(copy);
  }

  /// Reasons keep the order the family arranged them in (list position).
  static List<AbsenceReason> _sortedReasons(List<AbsenceReason> input) =>
      List<AbsenceReason>.unmodifiable(input);
}
