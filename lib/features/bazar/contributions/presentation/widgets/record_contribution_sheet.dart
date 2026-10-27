import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/presentation/controllers/contribution_form_controller.dart';
import 'package:family_hub/features/bazar/contributions/presentation/controllers/contribution_form_state.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/contribution_form_fields.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the contribution sheet for [mode].
///
/// `openingBalance: true` runs `RecordOpeningBalance` instead (the "Set up the
/// fund" card); everything else runs the mode's contribution use case.
Future<void> showContributionSheet(
  BuildContext context,
  ContributionFormMode mode, {
  required MonthKey month,
  String? contributionId,
  bool openingBalance = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: ContributionSheet(
      mode: mode,
      month: month,
      contributionId: contributionId,
      openingBalance: openingBalance,
    ),
  ),
);

/// The sheet body: person, amount, date, method; one save button.
class ContributionSheet extends ConsumerWidget {
  const ContributionSheet({
    required this.mode,
    required this.month,
    this.contributionId,
    this.openingBalance = false,
    super.key,
  });

  final ContributionFormMode mode;
  final MonthKey month;
  final String? contributionId;
  final bool openingBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final args = ContributionFormArgs(
      month: month,
      contributionId: contributionId,
    );
    final state = ref.watch(contributionFormProvider(args));
    final locked = ref.watch(monthLockedProvider(month));

    // Closing from a post-frame callback, never during build.
    if (state.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted) navigator.maybePop();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title(l10n, mode, openingBalance),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (locked)
            FormBanner(
              icon: Icons.lock_outline,
              text: l10n.bazarErrMonthLocked,
              color: Theme.of(context).colorScheme.outline,
            ),
          ContributionFormFields(
            args: args,
            locked: locked || openingBalance,
          ),
          if (state.failure case final failure?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.bazarFailureMessage(failure),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          BusyButton(
            key: const ValueKey('contribution-save'),
            label: _saveLabel(l10n, mode, openingBalance),
            busy: state.saving,
            busyLabel: l10n.loadingSemantics,
            onPressed: locked
                ? null
                : () async {
                    if (openingBalance) {
                      await _saveOpening(ref, args, state, context);
                    } else {
                      await ref
                          .read(contributionFormProvider(args).notifier)
                          .submit();
                    }
                  },
          ),
        ],
      ),
    );
  }

  /// `RecordOpeningBalance`: the first month plus the money already there.
  /// A failure is shown in the sheet's banner; success closes it.
  static Future<void> _saveOpening(
    WidgetRef ref,
    ContributionFormArgs args,
    ContributionFormState state,
    BuildContext context,
  ) async {
    final controller = ref.read(contributionFormProvider(args).notifier);
    final failure = await controller.saveOpening();
    if (failure == null || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.bazarFailureMessage(failure))));
  }

  static String _title(
    AppLocalizations l10n,
    ContributionFormMode mode,
    bool opening,
  ) {
    if (opening) return l10n.fundOpeningBalance;
    return switch (mode) {
      ContributionFormMode.record => l10n.fundAddContribution,
      ContributionFormMode.request => l10n.fundRequestContribution,
      ContributionFormMode.editPending => l10n.fundEditRequest,
      ContributionFormMode.requestChange => l10n.fundRequestChange,
    };
  }

  static String _saveLabel(
    AppLocalizations l10n,
    ContributionFormMode mode,
    bool opening,
  ) => switch (mode) {
    _ when opening => l10n.fundSaveOpening,
    ContributionFormMode.record => l10n.fundSaveContribution,
    ContributionFormMode.request => l10n.fundSendRequest,
    ContributionFormMode.editPending => l10n.actionSave,
    ContributionFormMode.requestChange => l10n.fundSendChangeRequest,
  };
}


