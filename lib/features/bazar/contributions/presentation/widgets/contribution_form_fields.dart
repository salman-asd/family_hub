import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/presentation/controllers/contribution_form_controller.dart';
import 'package:family_hub/features/bazar/contributions/presentation/controllers/contribution_form_state.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/date_chip_field.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fields of the contribution sheet: person, amount, date, method.
///
/// The person picker is locked to the signed-in member for a request and free
/// for a manager recording someone's payment.  Nothing is parsed here: the
/// live text goes to the controller, which owns `Money.parse`.
class ContributionFormFields extends ConsumerStatefulWidget {
  const ContributionFormFields({
    required this.args,
    required this.locked,
    super.key,
  });

  final ContributionFormArgs args;

  /// Closed month, or the opening-balance form: everything is read-only.
  final bool locked;

  @override
  ConsumerState<ContributionFormFields> createState() =>
      _ContributionFormFieldsState();
}

class _ContributionFormFieldsState
    extends ConsumerState<ContributionFormFields> {
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: ref.read(contributionFormProvider(widget.args)).amountText,
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final args = widget.args;
    final state = ref.watch(contributionFormProvider(args));
    final controller = ref.read(contributionFormProvider(args).notifier);
    final members = ref.watch(membersProvider).value ?? const <Member>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.canPickMember && !widget.locked) ...[
          PersonPicker(
            key: const ValueKey('contribution-member'),
            label: l10n.fundMemberLabel,
            selectedId: state.memberId,
            options: <PersonOption>[
              for (final member in members)
                if (member.isActive)
                  PersonOption(
                    id: member.uid,
                    name: member.displayName,
                    avatarKey: member.avatarKey,
                  ),
            ],
            onChanged: controller.setMember,
          ),
          const SizedBox(height: 16),
        ],
        AmountField(
          key: const ValueKey('contribution-amount'),
          controller: _amount,
          label: l10n.fundAmountLabel,
          errorText: _amountError(l10n, state.amountError),
          enabled: !widget.locked && !state.saving,
          autofocus: true,
          onChanged: controller.setAmount,
        ),
        const SizedBox(height: 8),
        DateChipField(
          key: const ValueKey('contribution-date'),
          date: state.date,
          enabled: !widget.locked && !state.saving,
          onPicked: controller.setDate,
          // A use-case date rejection belongs on the date, not as a banner.
          errorText: _isFutureDate(state.failure) ? l10n.bazarErrFutureDate : null,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.fundMethodLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        ChoiceWrap<ContributionMethod>(
          selected: state.method,
          onChanged: (method) => controller.setMethod(method),
          options: <ChoiceOption<ContributionMethod>>[
            for (final method in ContributionMethod.values)
              ChoiceOption(method, _methodLabel(l10n, method), key: ValueKey('method-${method.name}')),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static bool _isFutureDate(AppFailure? failure) =>
      failure is Validation && failure.field == 'dateKey';

  static String? _amountError(AppLocalizations l10n, String? code) =>
      switch (code) {
        'required' => l10n.bazarErrRequired,
        'invalid_amount' => l10n.bazarErrInvalidAmount,
        'amount_not_positive' => l10n.bazarErrAmountNotPositive,
        'negative' => l10n.bazarErrNegative,
        'too_many_decimals' => l10n.bazarErrTooManyDecimals,
        'too_large' => l10n.bazarErrTooLarge,
        _ => null,
      };

  static String _methodLabel(AppLocalizations l10n, ContributionMethod m) =>
      switch (m) {
        ContributionMethod.cash => l10n.fundMethodCash,
        ContributionMethod.bkash => l10n.fundMethodBkash,
        ContributionMethod.nagad => l10n.fundMethodNagad,
        ContributionMethod.bank => l10n.fundMethodBank,
        ContributionMethod.other => l10n.fundMethodOther,
      };
}
