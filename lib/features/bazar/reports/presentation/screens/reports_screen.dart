import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:family_hub/features/bazar/reports/presentation/report_providers.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/contributions_tab.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/report_preset_bar.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/report_tab_bodies.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/report_tabs.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reports (`/bazar/reports`, P2-25).
///
/// A preset chip row, a custom range picker and seven tabs.  Everyone with
/// `viewFamilyReports` sees all of them; a member without it sees ONLY the
/// contributions tab, because contributions are visible to every active member
/// (D-P2-5).  Every figure comes from `ReportEngine` via `reportDataProvider`:
/// this screen never adds anything up itself.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canView = ref.can(Permission.viewFamilyReports);
    if (!canView) return const _ContributionsOnly();

    final query = ref.watch(reportQueryProvider);
    return DefaultTabController(
      length: ReportTab.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.reportTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: <Widget>[
              for (final tab in ReportTab.values)
                Tab(
                  key: ValueKey('report-tab-${tab.name}'),
                  text: tabLabel(l10n, tab),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            ReportPresetBar(
              query: query,
              onPreset: (preset) => pickPreset(context, ref, preset),
            ),
            Expanded(child: ReportTabBodies(query: query)),
          ],
        ),
      ),
    );
  }
}

/// The fallback for a member without `viewFamilyReports`: only contributions.
class _ContributionsOnly extends ConsumerWidget {
  const _ContributionsOnly();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(reportQueryProvider);
    final month = contributionMonthFor(
      query.resolvedRange,
      ref.watch(familyDateKeysProvider).thisMonth(),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportTitle)),
      body: Column(
        children: [
          ReportPresetBar(
            query: query,
            onPreset: (preset) => pickPreset(context, ref, preset),
          ),
          Expanded(
            child: ContributionsTab(
              month: month,
              memberNames: memberNames(ref),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the custom range picker (never past today) or sets a preset.
Future<void> pickPreset(
  BuildContext context,
  WidgetRef ref,
  RangePreset preset,
) async {
  final controller = ref.read(reportQueryProvider.notifier);
  if (preset != RangePreset.custom) {
    controller.setPreset(preset);
    return;
  }
  final today = ref.read(currentDateKeyProvider);
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(today.year - 5),
    lastDate: DateTime(today.year, today.month, today.day),
  );
  if (picked == null) return;
  controller.setPreset(
    RangePreset.custom,
    custom: DateKeyRange(
      DateKey(picked.start.year, picked.start.month, picked.start.day),
      DateKey(picked.end.year, picked.end.month, picked.end.day),
    ),
  );
}
