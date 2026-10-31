import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/today_sections.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/presentation/widgets/day_part_section.dart';
import 'package:family_hub/features/chores/presentation/widgets/today_header.dart';
import 'package:family_hub/features/chores/presentation/widgets/today_row.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What to do with today's chores (P3-15).
///
/// Sections: Overdue (pinned), the day parts of the pending work, then "done
/// today" (collapsed). The "Mine / Whole family" toggle filters the SAME list,
/// so switching it never reads Firestore again (D-P3-8); it starts at the
/// family's `defaultScope` setting (U-07). Rows are `TodayRow`s.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// The person's own choice; null means "follow the family default".
  CalendarScopeKind? _chosen;
  bool _doneExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ref.watch(familyDateKeysProvider).today();
    final monthProvider = monthOccurrencesProvider(today.monthKey);
    final month = ref.watch(monthProvider);
    final all = ref.watch(todayItemsProvider);
    final uid = ref.watch(currentUidProvider);
    final scope = _chosen ?? ref.watch(choreSettingsProvider).defaultScope;
    final scoped = scope == CalendarScopeKind.mine ? mineOnly(all, uid) : all;

    final Widget body;
    if (month.hasError && !month.hasValue) {
      final error = month.error;
      body = ErrorView(
        message: l10n.choresFailureMessage(
          error is AppFailure ? error : Unknown(error),
        ),
        onRetry: () => ref.invalidate(monthProvider),
      );
    } else if (!month.hasValue) {
      body = const LoadingView();
    } else {
      body = Column(
        children: [
          TodayHeader(
            progress: TodayProgress.of(scoped),
            scope: scope,
            onScope: (value) => setState(() => _chosen = value),
            formatters: ref.watch(appFormattersProvider),
          ),
          Expanded(child: _list(context, scoped)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      body: body,
    );
  }

  Widget _list(BuildContext context, List<ChoreItem> scoped) {
    final l10n = context.l10n;
    final t = context.tokens;
    if (scoped.isEmpty) {
      return EmptyState(
        icon: Icons.wb_sunny_outlined,
        title: l10n.todayEmptyTitle,
        message: l10n.todayEmptyMessage,
      );
    }
    final sections = TodaySections.of(scoped);
    final formatters = ref.watch(appFormattersProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (sections.overdue.isNotEmpty) ...[
          SectionHeader(title: l10n.todaySectionOverdue),
          for (final item in sections.overdue) TodayRow(item: item),
          const SizedBox(height: 8),
        ],
        for (final (part, items) in groupByDayPart(sections.upcoming)) ...[
          DayPartSection(part: part, count: items.length),
          for (final item in items) TodayRow(item: item),
        ],
        if (sections.allDone)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: l10n.todayAllDoneTitle,
              message: l10n.todayAllDoneMessage,
            ),
          ),
        if (sections.done.isNotEmpty) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _doneExpanded = !_doneExpanded),
            child: Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title:
                        '${l10n.todaySectionDone} '
                        '(${formatters.number(sections.done.length)})',
                  ),
                ),
                Icon(
                  _doneExpanded ? Icons.expand_less : Icons.expand_more,
                  color: t.textSecondary,
                ),
              ],
            ),
          ),
          if (_doneExpanded)
            for (final item in sections.done) TodayRow(item: item),
        ],
      ],
    );
  }
}
