import 'dart:convert';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/features/bazar/budgets/presentation/budget_providers.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/reports/presentation/report_csv_builder.dart';
import 'package:family_hub/features/bazar/reports/presentation/report_pdf_builder.dart';
import 'package:family_hub/features/bazar/reports/domain/report_export_rows.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:family_hub/features/bazar/reports/domain/report_text_builder.dart';
import 'package:family_hub/features/bazar/reports/presentation/report_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReportShareActions extends ConsumerWidget {
  const ReportShareActions({required this.query, super.key});

  final ReportQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canExport = ref.can(Permission.exportData);
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.reportShareText,
          onPressed: () => _shareText(context, ref, export: false),
          icon: const Icon(Icons.share_outlined),
        ),
        if (canExport)
          PopupMenuButton<_ExportAction>(
            tooltip: l10n.reportExport,
            onSelected: (action) {
              switch (action) {
                case _ExportAction.csv:
                  _shareCsv(context, ref);
                  break;
                case _ExportAction.pdf:
                  _shareText(context, ref, export: true);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ExportAction.csv,
                child: Text(l10n.reportExportCsv),
              ),
              PopupMenuItem(
                value: _ExportAction.pdf,
                child: Text(l10n.reportExportPdf),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _shareText(
    BuildContext context,
    WidgetRef ref, {
    required bool export,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final failureMessage = context.l10n.reportExportFailed;
    final reportTitle = context.l10n.reportTitle;
    try {
      final text = await _buildText(context, ref, export: export);
      if (!export) {
        await SharePlus.instance.share(ShareParams(text: text));
        return;
      }
      final font = await rootBundle.load(
        'assets/fonts/HindSiliguri-Regular.ttf',
      );
      final bytes = await ReportPdfBuilder.build(
        title: reportTitle,
        reportText: text,
        fontData: font,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'family_report_${query.resolvedRange.start}.pdf',
      );
    } on AppFailure {
      _showFailure(messenger, failureMessage);
    } on PlatformException {
      _showFailure(messenger, failureMessage);
    }
  }

  Future<String> _buildText(
    BuildContext context,
    WidgetRef ref, {
    required bool export,
  }) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final report = await ref.read(reportDataProvider.future);
    final ReportExportRows? exportedRows = export
        ? await ref.read(reportExportRowsProvider(query.resolvedRange).future)
        : null;
    final chores = exportedRows == null
        ? await ref.read(reportChoreRowsProvider(query.resolvedRange).future)
        : exportedRows.chores;
    final range = query.resolvedRange;
    final budget = range.start.monthKey == range.end.monthKey
        ? await ref.read(monthBudgetProvider(range.start.monthKey).future)
        : null;
    await ref.read(fundTransactionsProvider.future);
    if (ref.read(fundWindowOverflowProvider)) {
      throw const Validation('fund', 'export_limit');
    }
    final isBangla = languageCode == 'bn';
    final catalog = ref.read(catalogIndexProvider);
    final categories = <ReportTextCategory>[
      for (final total in report.categories)
        ReportTextCategory(
          name:
              catalog.categoriesById[total.categoryId]?.displayName(
                bangla: isBangla,
              ) ??
              total.categoryId,
          total: total.total,
        ),
    ];
    var completed = 0;
    var remaining = 0;
    var awaiting = 0;
    for (final chore in chores) {
      final status = effectiveStatus(chore);
      if (status == ChoreStatus.completed || status == ChoreStatus.verified) {
        completed++;
        if (status == ChoreStatus.completed &&
            chore.verification == VerificationMode.required) {
          awaiting++;
        }
      } else if (status.isOpen) {
        remaining++;
      }
    }
    final period = lengthInDays(range) == 1
        ? ReportTextPeriod.daily
        : lengthInDays(range) <= 7
        ? ReportTextPeriod.weekly
        : ReportTextPeriod.monthly;
    return ReportTextBuilder.build(
      ReportTextData(
        period: period,
        range: range,
        bazarTotal: report.summary.total,
        categories: categories,
        choresCompleted: completed,
        choresRemaining: remaining,
        choresAwaitingVerification: awaiting,
        budget: budget?.totalEstimate,
        spent: report.summary.total,
        fundBalance: ref.read(fundBalanceProvider),
      ),
      languageCode: languageCode,
    );
  }

  Future<void> _shareCsv(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failureMessage = context.l10n.reportExportFailed;
    try {
      final rows = await ref.read(
        reportExportRowsProvider(query.resolvedRange).future,
      );
      final range = query.resolvedRange;
      final files = <XFile>[
        _csvFile(
          'expenses_${range.start}_${range.end}.csv',
          ReportCsvBuilder.expenses(rows.expenses),
        ),
        _csvFile(
          'contributions_${range.start}_${range.end}.csv',
          ReportCsvBuilder.contributions(rows.contributions),
        ),
        _csvFile(
          'chores_${range.start}_${range.end}.csv',
          ReportCsvBuilder.chores(rows.chores),
        ),
      ];
      await SharePlus.instance.share(ShareParams(files: files));
    } on AppFailure {
      _showFailure(messenger, failureMessage);
    } on PlatformException {
      _showFailure(messenger, failureMessage);
    }
  }

  XFile _csvFile(String name, String content) =>
      XFile.fromData(utf8.encode(content), mimeType: 'text/csv', name: name);

  void _showFailure(ScaffoldMessengerState messenger, String message) {
    if (!messenger.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _ExportAction { csv, pdf }
