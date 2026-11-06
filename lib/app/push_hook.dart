import 'dart:async';

import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/app/routing/session_providers.dart';
import 'package:family_hub/core/localization/locale_controller.dart';
import 'package:family_hub/core/notifications/presentation/push_providers.dart';
import 'package:family_hub/core/notifications/presentation/push_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushOrchestrationProvider = Provider<void>((ref) {
  PushController controller() => ref.read(pushControllerProvider);
  PushController? activeController;
  var active = false;

  void updateSession(SessionPhase phase) {
    if (phase == SessionPhase.loading || phase == SessionPhase.failed) return;
    if (phase == SessionPhase.active) {
      final uid = ref.read(currentUidProvider);
      if (uid == null) return;
      active = true;
      activeController = controller();
      unawaited(
        activeController!.onSessionActive(
          uid: uid,
          languageCode: ref.read(localeControllerProvider).languageCode,
        ),
      );
      return;
    }
    if (active) {
      active = false;
      unawaited(activeController!.onSessionEnded());
    }
  }

  ref.listen<SessionPhase>(
    sessionPhaseProvider,
    (_, phase) => updateSession(phase),
  );
  ref.listen(localeControllerProvider, (_, locale) {
    if (active) {
      unawaited(activeController!.onLanguageChanged(locale.languageCode));
    }
  });
  updateSession(ref.read(sessionPhaseProvider));
});
