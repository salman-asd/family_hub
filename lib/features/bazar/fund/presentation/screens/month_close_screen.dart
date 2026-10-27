import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/domain/month_choices.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/month_close_actions.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/month_close_preview_card.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/month_list.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/month_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Close or reopen a Bazar month (`/bazar/month-close`, `closeBazarMonth`).
///
/// Past months first, then a preview of the selected one (received, spent,
/// reimbursed, closing balance, open advances), then Close month or, for a
/// closed month, Reopen (a note is required).  Closing makes the month
/// read-only and carries the balance into the next one.
class MonthCloseScreen extends ConsumerStatefulWidget {
  const MonthCloseScreen({super.key});

  @override
  ConsumerState<MonthCloseScreen> createState() => _MonthCloseScreenState();
}

class _MonthCloseScreenState extends ConsumerState<MonthCloseScreen> {
  MonthKey? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canClose = ref.can(Permission.closeBazarMonth);
    final thisMonth = ref.watch(familyDateKeysProvider).thisMonth();
    final closings = ref.watch(monthClosingsProvider);

    if (!canClose) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.monthCloseTitle)),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: l10n.bazarErrNotAllowed,
          message: l10n.monthCloseManagerOnly,
        ),
      );
    }

    final selected = _selected ?? thisMonth;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.monthCloseTitle)),
      body: closings.when(
        loading: () => const LoadingView(lines: 5),
        error: (_, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: l10n.errorNetwork,
          actionLabel: l10n.actionRetry,
          onAction: () => ref.invalidate(monthClosingsProvider),
        ),
        data: (rows) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MonthSwitcher(
              month: selected,
              onChanged: (month) => setState(() => _selected = month),
            ),
            const SizedBox(height: 8),
            if (selected == thisMonth)
              FormBanner(
                icon: Icons.info_outline,
                text: l10n.monthCloseCurrentHint,
                color: Theme.of(context).colorScheme.outline,
              ),
            MonthClosePreviewCard(month: selected),
            const SizedBox(height: 8),
            MonthCloseActions(
              month: selected,
              closing: closingOf(rows, selected),
            ),
            const SizedBox(height: 16),
            MonthList(
              months: monthChoices(thisMonth, rows),
              selected: selected,
              closings: rows,
              onSelected: (month) => setState(() => _selected = month),
            ),
          ],
        ),
      ),
    );
  }
}


