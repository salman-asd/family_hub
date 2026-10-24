import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_controller.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/duplicate_warning_sheet.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_form_body.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_text_controllers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Add an expense, or edit one when [editingId] is set (`/bazar/expenses/new`,
/// `/bazar/expenses/:id/edit`).  The most-used screen: item, amount, Save.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({this.editingId, super.key});

  final String? editingId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final ExpenseTextControllers _text = ExpenseTextControllers();

  ExpenseFormArgs get _args => ExpenseFormArgs(editingId: widget.editingId);

  @override
  void initState() {
    super.initState();
    ref.listenManual<ExpenseFormState>(
      expenseFormProvider(_args),
      (_, next) => _text.sync(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.bazar);
    }
  }

  Future<void> _save({required bool addAnother}) async {
    final form = ref.read(expenseFormProvider(_args).notifier);
    var outcome = await form.save(addAnother: addAnother);
    if (!mounted) return;

    final duplicate = ref.read(expenseFormProvider(_args)).duplicate;
    if (outcome == null && duplicate != null) {
      final confirmed = await showDuplicateWarningSheet(
        context,
        itemName: duplicate.existing.itemName,
        amount: duplicate.existing.total,
      );
      if (!mounted) return;
      if (!confirmed) {
        form.dismissDuplicate();
        return;
      }
      outcome = await form.saveConfirmed(addAnother: addAnother);
      if (!mounted) return;
    }
    if (outcome == null) return;

    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.editingId == null ? l10n.expenseSaved : l10n.expenseUpdated,
        ),
      ),
    );
    if (outcome.addAnother) {
      _text.amountFocus.unfocus();
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(expenseFormProvider(_args));
    final locked = ref.watch(monthLockedProvider(state.date.monthKey));
    final editing = widget.editingId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l10n.expenseEditTitle : l10n.expenseAddTitle),
        actions: [
          if (!editing)
            PopupMenuButton<String>(
              key: const ValueKey('expense-menu'),
              onSelected: (_) => context.pushReplacement(AppRoutes.bazarTripNew),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'trip',
                  child: Text(l10n.expenseMenuTrip),
                ),
              ],
            ),
        ],
      ),
      body: switch (state.load) {
        ExpenseFormLoad.loading => const LoadingView(lines: 5),
        ExpenseFormLoad.failed => ErrorView(
          message: state.failure == null
              ? l10n.bazarErrUnknown
              : l10n.bazarFailureMessage(state.failure!),
        ),
        ExpenseFormLoad.ready => _buildForm(context, state, locked: locked),
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    ExpenseFormState state, {
    required bool locked,
  }) {
    final l10n = context.l10n;
    final canSave = !locked && !state.saving;
    return ListView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        ExpenseFormBody(args: _args, text: _text, locked: locked),
        const SizedBox(height: 16),
        BusyButton(
          key: const ValueKey('expense-save'),
          label: l10n.actionSave,
          busy: state.saving,
          busyLabel: l10n.loadingSemantics,
          onPressed: canSave ? () => _save(addAnother: false) : null,
        ),
        if (!state.editing) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              key: const ValueKey('expense-save-another'),
              onPressed: canSave ? () => _save(addAnother: true) : null,
              child: Text(l10n.expenseSaveAddAnother),
            ),
          ),
        ],
      ],
    );
  }
}
