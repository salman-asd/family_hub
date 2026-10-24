import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/trip_form_controller.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/date_chip_field.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_field_errors.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/funding_selector.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/trip_line_sheet.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/trip_line_tile.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/total_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Many items bought together: shared date, shop and payer, one Save
/// (`/bazar/trip/new`).
class BazarTripScreen extends ConsumerStatefulWidget {
  const BazarTripScreen({super.key});

  @override
  ConsumerState<BazarTripScreen> createState() => _BazarTripScreenState();
}

class _BazarTripScreenState extends ConsumerState<BazarTripScreen> {
  final TextEditingController _shop = TextEditingController();

  @override
  void dispose() {
    _shop.dispose();
    super.dispose();
  }

  Future<void> _addLine() async {
    final form = ref.read(tripFormProvider.notifier);
    final line = await showTripLineSheet(context, newId: form.newLineId);
    if (line != null && mounted) form.addLine(line);
  }

  Future<void> _editLine(int index, TripLineDraft line) async {
    final form = ref.read(tripFormProvider.notifier);
    final edited = await showTripLineSheet(
      context,
      newId: form.newLineId,
      initial: line,
    );
    if (edited != null && mounted) form.updateLine(index, edited);
  }

  void _remove(int index) {
    final form = ref.read(tripFormProvider.notifier);
    final removed = form.removeLine(index);
    if (removed == null) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.tripLineRemoved),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => form.insertLine(index, removed),
          ),
        ),
      );
  }

  Future<void> _save() async {
    final trip = await ref.read(tripFormProvider.notifier).save();
    if (trip == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.tripSaved)));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.bazar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final state = ref.watch(tripFormProvider);
    final form = ref.read(tripFormProvider.notifier);
    final members = ref.watch(bazarMemberOptionsProvider);
    final locked = ref.watch(monthLockedProvider(state.date.monthKey));
    final failure = state.failure;
    final canSave = !locked && !state.saving && state.lines.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (locked)
            FormBanner(
              icon: Icons.lock_outline,
              text: l10n.bazarErrMonthLocked,
              color: t.warning,
            ),
          if (failure != null)
            FormBanner(
              icon: Icons.error_outline,
              text: l10n.bazarFailureMessage(failure),
              color: t.danger,
            ),
          DateChipField(
            date: state.date,
            enabled: !state.saving && !locked,
            errorText: fieldErrorText(l10n, state.fieldErrors, 'dateKey'),
            onPicked: form.setDate,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('trip-shop'),
            controller: _shop,
            onChanged: form.setShop,
            decoration: InputDecoration(labelText: l10n.expenseShopField),
          ),
          const SizedBox(height: 16),
          FundingSelector(
            funding: state.funding,
            onFundingChanged: form.setFunding,
            members: members,
            paidById: state.paidByMemberId,
            onPaidByChanged: form.setPaidBy,
            errorText: fieldErrorText(l10n, state.fieldErrors, 'paidByMemberId'),
            enabled: !state.saving,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tripLinesCount(state.lines.length.toString()),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: t.textSecondary),
          ),
          if (state.lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.tripEmpty,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
              ),
            ),
          for (var i = 0; i < state.lines.length; i++)
            TripLineTile(
              key: ValueKey('trip-line-${state.lines[i].id}'),
              line: state.lines[i],
              onTap: () => _editLine(i, state.lines[i]),
              onRemove: () => _remove(i),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('trip-add-line'),
            onPressed: state.atLineLimit || state.saving ? null : _addLine,
            icon: const Icon(Icons.add),
            label: Text(l10n.tripAddLine),
          ),
          if (state.atLineLimit)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.tripLimitReached,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: t.warning),
              ),
            ),
          const SizedBox(height: 16),
          TotalDisplay(
            total: state.lines.isEmpty ? null : state.total,
            label: l10n.tripTotalLabel,
          ),
          const SizedBox(height: 16),
          BusyButton(
            key: const ValueKey('trip-save'),
            label: l10n.tripSaveAll,
            busy: state.saving,
            busyLabel: l10n.loadingSemantics,
            onPressed: canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}
