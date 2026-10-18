import 'package:family_hub/features/bazar/bazar_module.dart';
import 'package:family_hub/features/chores/chores_module.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:family_hub/modules/module_flags.dart';

/// The modules the app knows about, in navigation order.
class ModuleRegistry {
  ModuleRegistry(List<FamilyModule> modules)
      : modules = List.unmodifiable(modules) {
    final ids = modules.map((m) => m.id).toList();
    assert(
      ids.toSet().length == ids.length,
      'Module ids must be unique: $ids',
    );
  }

  /// The production registry.  A new module = one more entry here.
  factory ModuleRegistry.standard() => ModuleRegistry(const [
        ChoresModule(),
        BazarModule(),
      ]);

  final List<FamilyModule> modules;

  FamilyModule? byId(String id) {
    for (final m in modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Modules switched on by [flags], in registry order.
  List<FamilyModule> enabled(ModuleFlags flags) =>
      modules.where((m) => flags.isEnabled(m.id)).toList(growable: false);

  /// Modules switched off by [flags].
  List<FamilyModule> disabled(ModuleFlags flags) =>
      modules.where((m) => !flags.isEnabled(m.id)).toList(growable: false);
}
