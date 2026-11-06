import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/achievements_content.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  bool _sharingBusy = false;

  Future<void> _setSharing({
    required bool sharing,
    required String familyId,
    required String memberId,
    required EngagementSettings settings,
  }) async {
    if (_sharingBusy) return;
    setState(() => _sharingBusy = true);
    final result = await ref
        .read(setStatsSharingProvider)
        .call(
          familyId: familyId,
          memberId: memberId,
          sharing: sharing,
          settings: settings,
        );
    if (!mounted) return;
    setState(() => _sharingBusy = false);
    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_failureMessage(context, failure))),
      );
      return;
    }
    ref.invalidate(memberStatsProvider(memberId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final familyId = ref.watch(currentFamilyIdProvider);
    final memberId = ref.watch(currentUidProvider);
    if (familyId == null || memberId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.achievementsTitle)),
        body: const LoadingView(),
      );
    }
    final settings = ref.watch(engagementSettingsProvider(familyId));
    final stats = ref.watch(memberStatsProvider(memberId));
    final failure = settings.hasError && !settings.hasValue
        ? settings.error
        : stats.hasError && !stats.hasValue
        ? stats.error
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: failure != null
          ? ErrorView(
              message: l10n.errorNetwork,
              onRetry: () {
                ref.invalidate(engagementSettingsProvider(familyId));
                ref.invalidate(memberStatsProvider(memberId));
              },
            )
          : !settings.hasValue || !stats.hasValue
          ? const LoadingView()
          : !settings.requireValue.enabled
          ? EmptyState(
              icon: Icons.eco_outlined,
              title: l10n.achievementsDisabledTitle,
              message: l10n.engagementFailure_engagement_disabled,
            )
          : AchievementsContent(
              settings: settings.requireValue,
              stats:
                  stats.requireValue ??
                  MemberStats.empty(startedOn: settings.requireValue.startedOn),
              familyId: familyId,
              memberId: memberId,
              sharingBusy: _sharingBusy,
              onSharingChanged: (sharing) => _setSharing(
                sharing: sharing,
                familyId: familyId,
                memberId: memberId,
                settings: settings.requireValue,
              ),
            ),
    );
  }

  static String _failureMessage(BuildContext context, AppFailure failure) =>
      failure is Network
      ? context.l10n.errorNetwork
      : context.l10n.engagementSettingsSaveFailed;
}
