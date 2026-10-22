import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings_repository.dart';
import 'package:family_hub/features/bazar/settings/domain/usecases/update_bazar_settings.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final bazarSettingsRepositoryProvider = Provider<BazarSettingsRepository>(
  (ref) => throw UnimplementedError(
    'bazarSettingsRepositoryProvider must be overridden '
    '(bootstrap.dart / tests).',
  ),
);

/// The live `settings/bazar` document.  A missing document or a first load
/// still yields the defaults, so old families never see a loading crash.
final _bazarSettingsStreamProvider = StreamProvider<BazarSettings>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(BazarSettings.defaults);
  return ref.watch(bazarSettingsRepositoryProvider).watch(familyId);
});

/// Synchronous settings for every calculation that needs a value now.
final bazarSettingsProvider = Provider<BazarSettings>(
  (ref) =>
      ref.watch(_bazarSettingsStreamProvider).value ?? BazarSettings.defaults,
);

final updateBazarSettingsProvider = Provider<UpdateBazarSettings>(
  (ref) => UpdateBazarSettings(
    settings: ref.watch(bazarSettingsRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);
