part of 'recurrence_picker_sheet.dart';

/// The "days of the month" fields: a chip per day plus the month-end rule.
List<Widget> _daysOfMonthFields(
  BuildContext context, {
  required Set<int> days,
  required MonthEndMode monthEnd,
  required AppFormatters formatters,
  required ValueChanged<int> onToggleDay,
  required ValueChanged<MonthEndMode> onMonthEndChanged,
}) {
  final l10n = context.l10n;
  final t = context.tokens;
  return [
    Text(
      l10n.recurrencePickerDaysOfMonth,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: t.textSecondary),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var day = 1; day <= 31; day++)
          FilterChip(
            key: ValueKey<String>('recurrence_day_$day'),
            label: Text(formatters.number(day)),
            selected: days.contains(day),
            showCheckmark: true,
            onSelected: (_) => onToggleDay(day),
          ),
      ],
    ),
    const SizedBox(height: 16),
    Text(
      l10n.recurrencePickerMonthEnd,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: t.textSecondary),
    ),
    const SizedBox(height: 8),
    ChoiceWrap<MonthEndMode>(
      selected: monthEnd,
      onChanged: onMonthEndChanged,
      options: [
        ChoiceOption(MonthEndMode.clamp, l10n.recurrencePickerMonthEndClamp),
        ChoiceOption(MonthEndMode.skip, l10n.recurrencePickerMonthEndSkip),
      ],
    ),
  ];
}

/// The "nth weekday of the month" fields.
List<Widget> _nthWeekdayFields(
  BuildContext context, {
  required int nth,
  required int weekday,
  required int weekStart,
  required AppFormatters formatters,
  required ValueChanged<int> onNthChanged,
  required ValueChanged<int> onWeekdayChanged,
}) {
  final l10n = context.l10n;
  final t = context.tokens;
  return [
    Text(
      l10n.recurrencePickerNth,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: t.textSecondary),
    ),
    const SizedBox(height: 8),
    ChoiceWrap<int>(
      selected: nth,
      onChanged: onNthChanged,
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
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: t.textSecondary),
    ),
    const SizedBox(height: 8),
    ChoiceWrap<int>(
      selected: weekday,
      onChanged: onWeekdayChanged,
      options: [
        for (final day in WeekdayChips.order(weekStart))
          ChoiceOption(day, formatters.weekdayName(day)),
      ],
    ),
  ];
}

String _kindLabel(AppLocalizations l10n, RecurrenceKind kind) => switch (kind) {
  RecurrenceKind.once => l10n.recurrenceKindOnce,
  RecurrenceKind.daily => l10n.recurrenceKindDaily,
  RecurrenceKind.everyNDays => l10n.recurrenceKindEveryNDays,
  RecurrenceKind.weekdays => l10n.recurrenceKindWeekdays,
  RecurrenceKind.everyNWeeks => l10n.recurrenceKindEveryNWeeks,
  RecurrenceKind.daysOfMonth => l10n.recurrenceKindDaysOfMonth,
  RecurrenceKind.nthWeekday => l10n.recurrenceKindNthWeekday,
  RecurrenceKind.lastDay => l10n.recurrenceKindLastDay,
};

/// The Cancel / Done row under the fields.
class _PickerActions extends StatelessWidget {
  const _PickerActions({required this.onCancel, required this.onDone});

  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            child: Text(l10n.actionCancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: onDone, child: Text(l10n.actionDone)),
        ),
      ],
    );
  }
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
