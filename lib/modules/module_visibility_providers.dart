import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modules that are switched on AND that the signed-in member may see
/// (`FamilyModule.requiredPermission`), in registry order.  The shell builds
/// its tabs from this list.
final visibleModulesProvider = Provider<List<FamilyModule>>((ref) {
  return <FamilyModule>[
    for (final module in ref.watch(enabledModulesProvider))
      if (_allowed(ref, module)) module,
  ];
});

/// Every registered module that is NOT visible; its paths redirect home.
final hiddenModulesProvider = Provider<List<FamilyModule>>((ref) {
  final visible = ref.watch(visibleModulesProvider).map((m) => m.id).toSet();
  return <FamilyModule>[
    for (final module in ref.watch(moduleRegistryProvider).modules)
      if (!visible.contains(module.id)) module,
  ];
});

bool _allowed(Ref ref, FamilyModule module) {
  final required = module.requiredPermission;
  // No requirement: no read of the permission settings either.
  return required == null || ref.can(required);
}
