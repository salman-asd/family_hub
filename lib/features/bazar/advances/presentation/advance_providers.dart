import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_summary.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final advanceRepositoryProvider = Provider<AdvanceRepository>(
  (ref) => throw UnimplementedError(
    'advanceRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// Advances still pending or partly settled, live.
///
/// Someone who cannot settle advances may read only their own (a rules check is
/// not a filter), so the query is narrowed to their uid.
final openAdvancesProvider = StreamProvider<List<MemberAdvance>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  final uid = ref.watch(currentUidProvider);
  if (familyId == null || uid == null) {
    return Stream.value(const <MemberAdvance>[]);
  }
  final seesAll = ref.can(Permission.recordContribution);
  return ref
      .watch(advanceRepositoryProvider)
      .watchOpenAdvances(familyId, memberId: seesAll ? null : uid);
});

final advanceSummaryProvider = Provider<AdvanceSummary>(
  (ref) => AdvanceSummary.of(
    ref.watch(openAdvancesProvider).value ?? const <MemberAdvance>[],
  ),
);
