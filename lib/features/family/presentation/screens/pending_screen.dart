import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/failure_banner.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `/pending`.  Listens to nothing itself: the router already watches the
/// member document and leaves this screen the moment the member is approved.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(_cancelActionProvider);
    return _GateScreen(
      icon: Icons.hourglass_top_rounded,
      title: context.l10n.pendingTitle,
      message: context.l10n.pendingMessage,
      failure: action.failure,
      extra: TextButton(
        key: const Key('pending_cancel'),
        onPressed: action.busy
            ? null
            : () {
                final uid = ref.read(currentUidProvider);
                final familyId =
                    ref.read(membershipProvider).value?.familyId;
                if (uid == null || familyId == null) return;
                // The member document gets `removedAt`; the router then moves
                // to family choice by itself.
                ref.read(_cancelActionProvider.notifier).run(
                      () => ref.read(cancelJoinRequestProvider)(
                        actorUid: uid,
                        familyId: familyId,
                      ),
                    );
              },
        child: Text(context.l10n.pendingCancelRequest),
      ),
    );
  }
}

final _cancelActionProvider = newActionProvider();

/// `/disabled`.
class DisabledScreen extends ConsumerWidget {
  const DisabledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _GateScreen(
        icon: Icons.block_rounded,
        title: context.l10n.disabledTitle,
        message: context.l10n.disabledMessage,
      );
}

class _GateScreen extends ConsumerWidget {
  const _GateScreen({
    required this.icon,
    required this.title,
    required this.message,
    this.extra,
    this.failure,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? extra;
  final AppFailure? failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: EmptyState(icon: icon, title: title, message: message),
            ),
            if (failure != null) ...[
              FailureBanner(failure: failure!),
              const SizedBox(height: 8),
            ],
            if (extra != null) extra!,
            TextButton(
              onPressed: () => ref.read(signOutProvider).call(),
              child: Text(l10n.authSignOut),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
