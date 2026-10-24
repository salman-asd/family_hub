import 'dart:async';

import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/app/routing/session_providers.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `/splash`: shown while the first auth / profile / membership event is in
/// flight, or with a Retry when one of those reads failed.
///
/// When the session is still loading after [waitHint] (typically offline with
/// nothing cached yet) it explains that it is waiting for a connection and
/// offers Retry; the user is never signed out or sent to onboarding (rule 14).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.waitHint = const Duration(seconds: 8)});

  final Duration waitHint;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.waitHint, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() => _slow = false);
    _timer?.cancel();
    _timer = Timer(widget.waitHint, () {
      if (mounted) setState(() => _slow = true);
    });
    retrySession(ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failed = ref.watch(sessionPhaseProvider) == SessionPhase.failed;

    return Scaffold(
      body: SafeArea(
        child: (failed || _slow)
            ? Column(
                children: [
                  Expanded(
                    child: EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: failed ? l10n.errorUnknown : l10n.syncWaitingTitle,
                      message: failed ? null : l10n.syncWaitingMessage,
                      actionLabel: l10n.actionRetry,
                      onAction: _retry,
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
