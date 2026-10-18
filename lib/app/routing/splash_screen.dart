import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/app/routing/session_providers.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `/splash`: shown while the first auth / profile / membership event is in
/// flight, or with a Retry when one of those reads failed.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final failed = ref.watch(sessionPhaseProvider) == SessionPhase.failed;

    return Scaffold(
      body: SafeArea(
        child: failed
            ? Column(
                children: [
                  Expanded(
                    child: EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: l10n.errorUnknown,
                      actionLabel: l10n.actionRetry,
                      onAction: () => retrySession(ref),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(signOutProvider).call(),
                    child: Text(l10n.authSignOut),
                  ),
                  const SizedBox(height: 8),
                ],
              )
            : Center(
                child: Semantics(
                  label: l10n.loadingGeneric,
                  liveRegion: true,
                  child: const CircularProgressIndicator(),
                ),
              ),
      ),
    );
  }
}
