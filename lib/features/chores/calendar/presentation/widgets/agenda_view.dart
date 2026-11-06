import 'dart:async';

import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/domain/agenda_model.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/presentation/widgets/today_row.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'agenda_view_parts.dart';

/// The Agenda (P3-23): a list that grows in both directions from today.
///
/// * the Overdue block comes first, then today and the days after it, each day
///   under a sticky header;
/// * days before today scroll upwards (`center` = today), without sticky
///   headers (a reversed sliver has none);
/// * runs of days without chores collapse into one "N free days" chip;
/// * the ends carry "Show earlier / later weeks" (the window grows by whole
///   weeks up to the model's limit);
/// * a button jumps back to today.
class AgendaView extends ConsumerStatefulWidget {
  const AgendaView({super.key});

  @override
  ConsumerState<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends ConsumerState<AgendaView> {
  final GlobalKey _centerKey = GlobalKey(debugLabel: 'agenda_center');
  final ScrollController _scroll = ScrollController();
  AgendaWindow _window = const AgendaWindow();
  bool _away = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final away = _scroll.hasClients && _scroll.offset.abs() > 240;
    if (away != _away) setState(() => _away = away);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _jumpToToday() {
    if (!_scroll.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      unawaited(
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final model = ref.watch(agendaWindowModelProvider(_window));
    final Widget body;
    if (model.hasValue) {
      body = _list(context, model.requireValue);
    } else if (model.hasError) {
      final error = model.error;
      body = ErrorView(
        message: l10n.choresFailureMessage(
          error is AppFailure ? error : Unknown(error),
        ),
        onRetry: () => ref.invalidate(agendaWindowModelProvider(_window)),
      );
    } else {
      body = const LoadingView();
    }
    return Stack(
      children: [
        Positioned.fill(child: body),
        if (_away)
          PositionedDirectional(
            end: 16,
            bottom: 88,
            child: FloatingActionButton.small(
              key: const Key('calendar_jump_today'),
              tooltip: l10n.calendarJumpToToday,
              onPressed: _jumpToToday,
              child: const Icon(Icons.vertical_align_center_rounded),
            ),
          ),
      ],
    );
  }

  Widget _list(BuildContext context, AgendaModel model) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final today = ref.watch(todayKeyProvider);
    final selected = ref.watch(selectedDayProvider);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final headerExtent = 48 * scale.clamp(1.0, 2.0);

    final past = <AgendaEntry>[];
    final future = <AgendaEntry>[];
    for (final entry in model.entries) {
      switch (entry) {
        case AgendaOverdue():
          break;
        case AgendaDay(:final dateKey):
          (dateKey.isBefore(today) ? past : future).add(entry);
        case AgendaFreeDays(:final to):
          (to.isBefore(today) ? past : future).add(entry);
      }
    }

    // The reversed sliver lays its first child NEAREST the centre, so the past
    // is built newest-first and its last child ("earlier weeks") is the top.
    final reversedRows = <Widget>[
      for (final entry in past.reversed)
        ..._rowsOf(context, entry, formatters, selected).reversed,
      if (_window.canGoEarlier)
        _MoreButton(
          key: const Key('calendar_load_earlier'),
          label: l10n.calendarLoadEarlier,
          onPressed: () => setState(() => _window = _window.earlier()),
        ),
    ];

    final overdue = model.overdue;
    return CustomScrollView(
      key: const PageStorageKey<String>('calendar_agenda'),
      controller: _scroll,
      center: _centerKey,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => reversedRows[index],
            childCount: reversedRows.length,
          ),
        ),
        SliverToBoxAdapter(
          key: _centerKey,
          child: overdue == null
              ? const SizedBox.shrink()
              : _OverdueBlock(overdue: overdue, formatters: formatters),
        ),
        for (final entry in future)
          switch (entry) {
            final AgendaDay day => SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DayHeaderDelegate(
                    extent: headerExtent,
                    child: _DayHeader(
                      day: day,
                      formatters: formatters,
                      selected: day.dateKey == selected,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: TodayRow(item: day.items[index]),
                    ),
                    childCount: day.items.length,
                  ),
                ),
              ],
            ),
            final AgendaFreeDays free => SliverToBoxAdapter(
              child: _FreeDaysChip(count: free.count),
            ),
            AgendaOverdue() => const SliverToBoxAdapter(),
          },
        SliverToBoxAdapter(
          child: _window.canGoLater
              ? _MoreButton(
                  key: const Key('calendar_load_later'),
                  label: l10n.calendarLoadLater,
                  onPressed: () => setState(() => _window = _window.later()),
                )
              : const SizedBox(height: 24),
        ),
      ],
    );
  }

  /// The rows of one past entry in reading order (header first).
  List<Widget> _rowsOf(
    BuildContext context,
    AgendaEntry entry,
    AppFormatters formatters,
    DateKey selected,
  ) => switch (entry) {
    final AgendaDay day => <Widget>[
      _DayHeader(
        day: day,
        formatters: formatters,
        selected: day.dateKey == selected,
      ),
      for (final item in day.items)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: TodayRow(item: item),
        ),
    ],
    final AgendaFreeDays free => <Widget>[_FreeDaysChip(count: free.count)],
    AgendaOverdue() => const <Widget>[],
  };
}
