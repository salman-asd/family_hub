/// Which modules a family has switched on (`families/{id}/settings/modules`).
///
/// Default is "everything on": a module that has no entry is enabled, so a new
/// module appears for existing families without a data migration.
class ModuleFlags {
  const ModuleFlags([this._flags = const <String, bool>{}]);

  /// All modules enabled.
  static const ModuleFlags allOn = ModuleFlags();

  final Map<String, bool> _flags;

  /// True unless the family explicitly turned [moduleId] off.
  bool isEnabled(String moduleId) => _flags[moduleId] ?? true;

  /// A copy with [moduleId] switched to [enabled].
  ModuleFlags withFlag(String moduleId, {required bool enabled}) =>
      ModuleFlags({..._flags, moduleId: enabled});

  @override
  bool operator ==(Object other) {
    if (other is! ModuleFlags) return false;
    final keys = {..._flags.keys, ...other._flags.keys};
    return keys.every((k) => isEnabled(k) == other.isEnabled(k));
  }

  @override
  int get hashCode => Object.hashAll(
        (_flags.entries.where((e) => !e.value).map((e) => e.key).toList()
          ..sort()),
      );

  @override
  String toString() => 'ModuleFlags($_flags)';
}

/// Read port for module flags.
///
/// Firestore implementation: `FirestoreMembershipRepository` (`settings/modules`).
abstract interface class ModuleFlagsRepository {
  /// Emits the flags immediately, then on every change.
  Stream<ModuleFlags> watchModuleFlags(String familyId);
}
