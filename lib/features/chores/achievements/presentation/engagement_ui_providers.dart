import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final familyPublicStatsProvider =
    StreamProvider.autoDispose<Map<String, PublicStats>>((ref) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) {
        return Stream.value(const <String, PublicStats>{});
      }
      final settings = ref.watch(engagementSettingsProvider(familyId)).value;
      if (settings?.statsVisibility != StatsVisibility.levels) {
        return Stream.value(const <String, PublicStats>{});
      }
      return ref.watch(publicStatsRepositoryProvider).watchFamily(familyId);
    });
