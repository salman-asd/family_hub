import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings_repository.dart';

/// Small in-memory port for setting use-case tests.
class FakeBazarSettingsRepository implements BazarSettingsRepository {
  FakeBazarSettingsRepository([this.stored = BazarSettings.defaults]);

  BazarSettings stored;
  int saves = 0;
  AppFailure? nextFailure;
  final List<AuditEvent> events = <AuditEvent>[];

  @override
  Stream<BazarSettings> watch(String familyId) => Stream.value(stored);

  @override
  Future<Result<BazarSettings>> get(String familyId) async =>
      Success<BazarSettings>(stored);

  @override
  Future<Result<void>> save(
    String familyId,
    BazarSettings settings,
    AuditEvent event,
  ) async {
    saves++;
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Failure<void>(failure);
    }
    stored = settings;
    events.add(event);
    return const Success<void>(null);
  }
}
