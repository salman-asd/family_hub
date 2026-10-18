import 'dart:ui' show FontFeature;

import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/failure_banner.dart';
import 'package:family_hub/features/family/presentation/widgets/labels.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _inviteActionProvider = newActionProvider();

/// Admins and moderators create single-use codes (valid 7 days) and copy them
/// to share by hand.
class InvitationsScreen extends ConsumerStatefulWidget {
  const InvitationsScreen({super.key});

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(_inviteActionProvider.notifier).reset());
  }

  Future<void> _create() async {
    final uid = ref.read(currentUidProvider);
    final familyId = ref.read(currentFamilyIdProvider);
    if (uid == null || familyId == null) return;
    await ref.read(_inviteActionProvider.notifier).run(
          () => ref.read(createInvitationProvider)(
            actorUid: uid,
            familyId: familyId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final action = ref.watch(_inviteActionProvider);
    final invitations = ref.watch(invitationsProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final formatters = ref.watch(appFormattersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invitationsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                BusyButton(
                  key: const Key('invitation_create'),
                  label: l10n.invitationCreate,
                  busy: action.busy,
                  onPressed: _create,
                ),
                if (action.failure != null) ...[
                  const SizedBox(height: 12),
                  FailureBanner(failure: action.failure!),
                ],
              ],
            ),
          ),
          Expanded(
            child: invitations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: l10n.errorUnknown,
                actionLabel: l10n.actionRetry,
                onAction: () => ref.invalidate(invitationsProvider),
              ),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.mail_outline_rounded,
                      title: l10n.invitationsEmpty,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        for (final i in list)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              minVerticalPadding: 12,
                              title: SelectableText(
                                i.code,
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                '${l10n.invitationStatusLabel(i, now)} · '
                                '${l10n.invitationExpiresOn} '
                                '${formatters.fullDate(i.expiresAt.toLocal())}',
                                style: TextStyle(color: t.textSecondary),
                              ),
                              trailing: i.status == InvitationStatus.active &&
                                      !i.isExpiredAt(now)
                                  ? IconButton(
                                      tooltip: l10n.invitationCopy,
                                      icon: const Icon(Icons.copy_rounded),
                                      onPressed: () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        await Clipboard.setData(
                                          ClipboardData(text: i.code),
                                        );
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content:
                                                Text(l10n.invitationCopied),
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
