import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// A read-only field that shows a time of day and opens the system time picker
/// (road map 3.7, P3-04).
///
/// The value is wall-clock minutes after midnight (0 … 1439), the same unit the
/// chore shapes store (`dueMinutes`), so no screen converts between `TimeOfDay`
/// and stored minutes on its own. The text comes from [AppFormatters.timeOfDay]
/// (Bangla day part + digits switch).
class MinutesField extends StatelessWidget {
  const MinutesField({
    required this.label,
    required this.minutes,
    required this.formatters,
    required this.onChanged,
    this.clearable = true,
    this.enabled = true,
    super.key,
  });

  final String label;

  /// Current value, or `null` when no time is set (due at end of day).
  final int? minutes;

  /// The active [AppFormatters] (language + digits switch from the theme).
  final AppFormatters formatters;

  /// Called with the picked minutes, or `null` when cleared.
  final ValueChanged<int?> onChanged;

  final bool clearable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = minutes;
    final text = value == null
        ? l10n.minutesFieldNotSet
        : formatters.timeOfDay(value);

    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label, $text',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => _pick(context, value) : null,
        borderRadius: BorderRadius.circular(context.tokens.radiusMd),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            suffixIcon: value != null && clearable && enabled
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    tooltip: l10n.minutesFieldClear,
                    onPressed: () => onChanged(null),
                  )
                : const Icon(Icons.schedule_rounded),
          ),
          child: Text(text),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, int? value) async {
    final current = value == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(hour: value ~/ 60, minute: value % 60);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    onChanged(picked.hour * 60 + picked.minute);
  }
}
