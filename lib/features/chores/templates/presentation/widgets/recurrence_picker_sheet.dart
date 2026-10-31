import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/weekday_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens the recurrence picker and returns the chosen rule (or null on cancel).
Future<Recurrence?> showRecurrencePicker(
  BuildContext context, {
  required Recurrence initial,
  required DateKey startDate,
  required int weekStart,
  required AppFormatters formatters,
}) {
  return showModalBottomSheet<Recurrence>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _RecurrencePickerSheet(
      initial: initial,
      startDate: startDate,
      weekStart: weekStart,
      formatters: formatters,
    ),
  );
}

/// The eight repeat shapes of road map 3.2, with the fields each one needs.
///
/// The sheet edits a local copy and returns one value on "Done", so cancelling
/// never changes the template draft.
class _RecurrencePickerSheet extends StatefulWidget {
  const _RecurrencePickerSheet({
    required this.initial,
    required this.startDate,
    required this.weekStart,
    required this.formatters,
  });

  final Recurrence initial;
  final DateKey startDate;
  final int weekStart;
  final AppFormatters formatters;

  @override
  State<_RecurrencePickerSheet> createState() => _RecurrencePickerSheetState();
}

class _RecurrencePickerSheetState extends State<_RecurrencePickerSheet> {
  late RecurrenceKind _kind;
  late int _n;
  late DateKey _onceDate;
  late Set<int> _weekdays;
  late Set<int> _days;
  late MonthEndMode _monthEnd;
  late int _nth;
  late int _weekday;
  late final TextEditingController _nController;

  @override
  void initState() {
    super.initState();
    _kind = widget.initial.kind;
    _n = 2;
    _onceDate = widget.startDate;
    _weekdays = <int>{};
    _days = <int>{};
    _monthEnd = MonthEndMode.clamp;
    _nth = 1;
    _weekday = DateTime.monday;
    switch (widget.initial) {
      case OnceRecurrence(:final date):
        _onceDate = date;
      case EveryNDaysRecurrence(:final n):
        _n = n;
      case WeekdaysRecurrence(:final weekdays):
        _weekdays = weekdays.toSet();
      case EveryNWeeksRecurrence(:final n, :final weekdays):
        _n = n;
        _weekdays = weekdays.toSet();
      case DaysOfMonthRecurrence(:final days, :final monthEnd):
        _days = days.toSet();
        _monthEnd = monthEnd;
      case NthWeekdayRecurrence(:final nth, :final weekday):
        _nth = nth;
        _weekday = weekday;
      case DailyRecurrence() || LastDayRecurrence():
        break;
    }
    _nController = TextEditingController(text: '$_n');
  }

  @override
  void dispose() {
    _nController.dispose();
    super.dispose();
  }

  Recurrence get _result => switch (_kind) {
    RecurrenceKind.once => OnceRecurrence(_onceDate),
    RecurrenceKind.daily => const DailyRecurrence(),
    RecurrenceKind.everyNDays => EveryNDaysRecurrence(
      n: _n,
      anchor: widget.startDate,
    ),
    RecurrenceKind.weekdays => WeekdaysRecurrence(
      weekdays: _sorted(_weekdays),
    ),
    RecurrenceKind.everyNWeeks => EveryNWeeksRecurrence(
      n: _n,
      anchor: widget.startDate,
      weekdays: _sorted(_weekdays),
      weekStart: widget.weekStart,
    ),
    RecurrenceKind.daysOfMonth => DaysOfMonthRecurrence(
      days: _sorted(_days),
      monthEnd: _monthEnd,
    ),
    RecurrenceKind.nthWeekday => NthWeekdayRecurrence(
      nth: _nth,
      weekday: _weekday,
    ),
    RecurrenceKind.lastDay => const LastDayRecurrence(),
  };

  static List<int> _sorted(Set<int> values) => values.toList()..sort();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.recurrencePickerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ChoiceWrap<RecurrenceKind>(
                selected: _kind,
                onChanged: (kind) => setState(() => _kind = kind),
                options: [
                  for (final kind in RecurrenceKind.values)
                    ChoiceOption(
                      kind,
                      _kindLabel(l10n, kind),
                      key: ValueKey<String>('recurrence_kind_${kind.id}'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ..._fields(context, l10n, t),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.actionCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_result),
                      child: Text(l10n.actionDone),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _fields(
    BuildContext context,
    AppLocalizations l10n,
    AppTokens t,
  ) {
    switch (_kind) {
      case RecurrenceKind.once:
        return [
          _DateRow(
            label: l10n.recurrencePickerOnceDate,
            date: _onceDate,
            formatters: widget.formatters,
            onChanged: (date) => setState(() => _onceDate = date),
          ),
        ];
      case RecurrenceKind.daily:
        return const [];
      case RecurrenceKind.everyNDays:
        return [
          _NumberField(
            label: l10n.recurrencePickerEveryNDays,
            controller: _nController,
            onChanged: _setN,
          ),
        ];
      case RecurrenceKind.weekdays:
        return [_weekdayField(l10n)];
      case RecurrenceKind.everyNWeeks:
        return [
          _NumberField(
            label: l10n.recurrencePickerEveryNWeeks,
            controller: _nController,
            onChanged: _setN,
          ),
          const SizedBox(height: 12),
          _weekdayField(l10n),
        ];
      case RecurrenceKind.daysOfMonth:
        return [
          Text(
            l10n.recurrencePickerDaysOfMonth,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var day = 1; day <= 31; day++)
                FilterChip(
                  key: ValueKey<String>('recurrence_day_$day'),
                  label: Text(widget.formatters.number(day)),
                  selected: _days.contains(day),
                  showCheckmark: true,
                  onSelected: (_) => setState(() {
                    if (!_days.remove(day)) _days.add(day);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.recurrencePickerMonthEnd,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 8),
          ChoiceWrap<MonthEndMode>(
            selected: _monthEnd,
            onChanged: (mode) => setState(() => _monthEnd = mode),
            options: [
              ChoiceOption(
                MonthEndMode.clamp,
                l10n.recurrencePickerMonthEndClamp,
              ),
              ChoiceOption(
                MonthEndMode.skip,
                l10n.recurrencePickerMonthEndSkip,
              ),
            ],
          ),
        ];
      case RecurrenceKind.nthWeekday:
        return [
          Text(
            l10n.recurrencePickerNth,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 8),
          ChoiceWrap<int>(
            selected: _nth,
            onChanged: (value) => setState(() => _nth = value),
            options: [
              ChoiceOption(1, l10n.recurrenceNthFirst),
              ChoiceOption(2, l10n.recurrenceNthSecond),
              ChoiceOption(3, l10n.recurrenceNthThird),
              ChoiceOption(4, l10n.recurrenceNthFourth),
              ChoiceOption(-1, l10n.recurrenceNthLast),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.recurrencePickerWeekday,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 8),
          ChoiceWrap<int>(
            selected: _weekday,
            onChanged: (value) => setState(() => _weekday = value),
            options: [
              for (final day in WeekdayChips.order(widget.weekStart))
                ChoiceOption(day, widget.formatters.weekdayName(day)),
            ],
          ),
        ];
      case RecurrenceKind.lastDay:
        return const [];
    }
  }

  Widget _weekdayField(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.recurrencePickerWeekdays,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: context.tokens.textSecondary),
      ),
      const SizedBox(height: 8),
      WeekdayChips(
        selected: _weekdays,
        weekStartDay: widget.weekStart,
        formatters: widget.formatters,
        onChanged: (value) => setState(() => _weekdays = value),
      ),
    ],
  );

  void _setN(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null) return;
    setState(
      () => _n = parsed.clamp(RecurrenceLimits.minN, RecurrenceLimits.maxN),
    );
  }

  static String _kindLabel(AppLocalizations l10n, RecurrenceKind kind) =>
      switch (kind) {
        RecurrenceKind.once => l10n.recurrenceKindOnce,
        RecurrenceKind.daily => l10n.recurrenceKindDaily,
        RecurrenceKind.everyNDays => l10n.recurrenceKindEveryNDays,
        RecurrenceKind.weekdays => l10n.recurrenceKindWeekdays,
        RecurrenceKind.everyNWeeks => l10n.recurrenceKindEveryNWeeks,
        RecurrenceKind.daysOfMonth => l10n.recurrenceKindDaysOfMonth,
        RecurrenceKind.nthWeekday => l10n.recurrenceKindNthWeekday,
        RecurrenceKind.lastDay => l10n.recurrenceKindLastDay,
      };
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.formatters,
    required this.onChanged,
  });

  final String label;
  final DateKey date;
  final AppFormatters formatters;
  final ValueChanged<DateKey> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, ${formatters.fullDate(_asDate(date))}',
      excludeSemantics: true,
      child: OutlinedButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.event_outlined),
        label: Text('$label: ${formatters.fullDate(_asDate(date))}'),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asDate(date),
      firstDate: DateTime.utc(2000),
      lastDate: DateTime.utc(2100),
    );
    if (picked == null) return;
    onChanged(DateKey(picked.year, picked.month, picked.day));
  }

  static DateTime _asDate(DateKey key) =>
      DateTime.utc(key.year, key.month, key.day);
}
