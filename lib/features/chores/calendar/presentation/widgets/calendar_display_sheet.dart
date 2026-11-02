import 'dart:async';

import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/heat_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the display options of the calendar (P3-24).
Future<void> showCalendarDisplaySheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const CalendarDisplaySheet(),
    );

/// How the calendar looks, kept on this device only (D-P3-21): the heat tint
/// and, once something was changed, a way back to the family's defaults.
class CalendarDisplaySheet extends ConsumerWidget {
  const CalendarDisplaySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final heatOn = ref.watch(calendarHeatModeProvider) == HeatMode.workload;
    final followsFamily = ref.watch(calendarUsesFamilyDefaultsProvider);
    final prefs = ref.read(calendarPrefsProvider.notifier);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.calendarDisplayOptions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SwitchListTile(
              key: const Key('calendar_heat_switch'),
              contentPadding: EdgeInsets.zero,
              value: heatOn,
              title: Text(l10n.calendarHeatMode),
              subtitle: Text(l10n.calendarHeatModeHint),
              onChanged: (on) => unawaited(
                prefs.setHeatMode(on ? HeatMode.workload : HeatMode.off),
              ),
            ),
            if (heatOn)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: HeatLegend(),
              ),
            if (!followsFamily)
              TextButton(
                key: const Key('calendar_use_family_defaults'),
                onPressed: () => unawaited(prefs.useFamilyDefaults()),
                child: Text(l10n.calendarUseFamilyDefaults),
              ),
          ],
        ),
      ),
    );
  }
}
