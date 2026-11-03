import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who is away on which day (D-P3-12), built from the ACTIVE absence records.
///
/// While the stream has not answered (or failed) the index is empty, so a
/// screen shows the rota as if nobody were away and corrects itself the moment
/// the records arrive. A pending or rejected absence never counts. The
/// calendar, the projection and the chore items already read this provider.
final availabilityIndexProvider = Provider<AvailabilityIndex>((ref) {
  final records = ref.watch(availabilityProvider).value;
  if (records == null || records.isEmpty) return AvailabilityIndex.empty;
  return AvailabilityIndex.fromRecords(records);
});
