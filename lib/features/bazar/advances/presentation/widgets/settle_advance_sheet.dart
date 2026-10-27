import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/date_chip_field.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/locked_month_banner.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the settle sheet for [advance].
Future<bool> showSettleAdvanceSheet(
  BuildContext context,
  MemberAdvance advance,
) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SettleAdvanceSheet(advance: advance),
    ),
  );
  return saved ?? false;
}

/// The payment methods the sheet offers (mirrors `ContributionMethod`).
const List<_MethodOption> _methods = <_MethodOption>[
  _MethodOption('cash', _cash),
  _MethodOption('bkash', _bkash),
  _MethodOption('nagad', _nagad),
];

String _cash(AppLocalizations l10n) => l10n.fundMethodCash;
String _bkash(AppLocalizations l10n) => l10n.fundMethodBkash;
String _nagad(AppLocalizations l10n) => l10n.fundMethodNagad;

class _MethodOption {
  const _MethodOption(this.value, this.label);

  final String value;
  final String Function(AppLocalizations) label;
}

/// Pays a member back: the amount (prefilled with what is still owed), a date,
/// a method and a note.
///
/// An overpayment shows inline (`overpayment`), and the attempt is simply not
/// saved.  The write needs the server, so offline it shows the network message
/// and does not queue (rule 26).
class SettleAdvanceSheet extends ConsumerStatefulWidget {
  const SettleAdvanceSheet({required this.advance, super.key});

  final MemberAdvance advance;

  @override
  ConsumerState<SettleAdvanceSheet> createState() => _SettleAdvanceSheetState();
}

class _SettleAdvanceSheetState extends ConsumerState<SettleAdvanceSheet> {
  late final TextEditingController _amount;
  late DateKey _date;
  String? _method;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: moneyEditText(widget.advance.remaining),
    );
    _date = ref.read(currentDateKeyProvider);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final parsed = Money.parse(_amount.text);
    final amount = parsed.valueOrNull;
    if (amount == null || amount.paisa <= 0) {
      setState(() => _error = context.l10n.bazarErrInvalidAmount);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(settleAdvanceProvider)(
      actorUid: ref.read(currentUidProvider) ?? '',
      familyId: ref.read(currentFamilyIdProvider) ?? '',
      expenseId: widget.advance.expenseId,
      amount: amount,
      date: _date,
      method: _method,
    );
    final failure = result.failureOrNull;
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _saving = false;
        _error = context.l10n.bazarFailureMessage(failure);
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme;
    final locked = ref.watch(monthLockedProvider(_date.monthKey));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.advanceSettleTitle, style: style.titleLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${l10n.advanceRemaining}: ', style: style.bodyMedium),
              MoneyText(
                key: const ValueKey('settle-remaining'),
                value: widget.advance.remaining,
                style: style.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LockedMonthBanner(month: _date.monthKey),
          AmountField(
            key: const ValueKey('settle-amount'),
            controller: _amount,
            label: l10n.fundAmountLabel,
            enabled: !_saving,
            autofocus: true,
          ),
          const SizedBox(height: 8),
          DateChipField(
            date: _date,
            enabled: !_saving,
            onPicked: (date) => setState(() => _date = date),
          ),
          const SizedBox(height: 12),
          Text(l10n.fundMethodLabel, style: style.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final option in _methods)
                ChoiceChip(
                  key: ValueKey('settle-method-${option.value}'),
                  label: Text(option.label(l10n)),
                  selected: _method == option.value,
                  onSelected: (_) =>
                      setState(() => _method = option.value),
                ),
            ],
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                key: const ValueKey('settle-error'),
                style: style.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 16),
          BusyButton(
            key: const ValueKey('settle-save'),
            label: l10n.advanceSettleAction,
            busy: _saving,
            busyLabel: l10n.loadingSemantics,
            onPressed: locked ? null : _save,
          ),
        ],
      ),
    );
  }
}


