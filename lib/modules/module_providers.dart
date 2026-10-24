import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:family_hub/features/family/domain/module_flags.dart';
import 'package:family_hub/modules/module_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The module registry.  Override in tests to inject a custom set.
final moduleRegistryProvider = Provider<ModuleRegistry>(
  (ref) => ModuleRegistry.standard(),
);

/// Overridden in `bootstrap.dart`.
final moduleFlagsRepositoryProvider = Provider<ModuleFlagsRepository>(
  (ref) => throw UnimplementedError(
    'moduleFlagsRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// The family's module flags; "everything on" until a family is known or while
/// the first value is loading, so the navigation never flickers modules off.
final moduleFlagsProvider = Provider<ModuleFlags>((ref) {
  final membership = ref.watch(membershipProvider).value;
  final familyId = membership?.familyId;
  // Pending members cannot read family settings; keep the default for them.
  if (familyId == null || membership?.status != MembershipStatus.active) {
    return ModuleFlags.allOn;
  }
  final flags = ref.watch(_moduleFlagsStreamProvider(familyId));
  return flags.value ?? ModuleFlags.allOn;
});

final _moduleFlagsStreamProvider = StreamProvider.family<ModuleFlags, String>((
  ref,
  familyId,
) {
  return ref.watch(moduleFlagsRepositoryProvider).watchModuleFlags(familyId);
});

/// Enabled modules in registry order.
final enabledModulesProvider = Provider<List<FamilyModule>>((ref) {
  return ref
      .watch(moduleRegistryProvider)
      .enabled(ref.watch(moduleFlagsProvider));
});

/// Disabled modules in registry order.
final disabledModulesProvider = Provider<List<FamilyModule>>((ref) {
  return ref
      .watch(moduleRegistryProvider)
      .disabled(ref.watch(moduleFlagsProvider));
});
