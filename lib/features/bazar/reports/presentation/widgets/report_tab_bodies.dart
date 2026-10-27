import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:family_hub/features/bazar/reports/presentation/report_providers.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/contributions_tab.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/report_tabs.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tab area: loads the report once and shows the selected tab.
///
/// The tabs are inside a `DefaultTabController`, so the index is read from it;
/// the data is fetched ONCE for all tabs (one engine run per query).
class ReportTabBodies extends ConsumerWidget {
  const ReportTabBodies({required this.query, super.key});

  final ReportQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(reportDataProvider);

    return data.when(
      loading: () => const LoadingView(lines: 6),
      error: (_, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.errorNetwork,
        actionLabel: l10n.actionRetry,
        onAction: () => ref.invalidate(reportDataProvider),
      ),
      data: (report) {
        final index = DefaultTabController.of(context).index;
        final tab = ReportTab.values[index];
        return Column(
          children: [
            if (ref.watch(reportTruncatedProvider))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: FormBanner(
                  icon: Icons.filter_alt_off_outlined,
                  text: l10n.reportTruncated,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            Expanded(
              child: switch (tab) {
                ReportTab.summary => SummaryTab(data: report, query: query),
                ReportTab.categories => CategoriesTab(
                  data: report,
                  byCategory: ref.watch(catalogIndexProvider).categoriesById,
                ),
                ReportTab.items => ItemsTab(data: report),
                ReportTab.days => DaysTab(data: report),
                ReportTab.members => MembersTab(
                  data: report,
                  memberNames: memberNames(ref),
                ),
                ReportTab.dryGroceries => DryGroceriesTab(data: report),
                ReportTab.contributions => ContributionsTab(
                  month: contributionMonthFor(
                    query.resolvedRange,
                    ref.watch(familyDateKeysProvider).thisMonth(),
                  ),
                  memberNames: memberNames(ref),
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

/// uid -> display name for every member the app knows about.
Map<String, String> memberNames(WidgetRef ref) => <String, String>{
  for (final member in ref.watch(membersProvider).value ?? const <Member>[])
    member.uid: member.displayName,
};
