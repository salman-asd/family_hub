import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/notifications/domain/reminder_settings.dart';
import 'package:flutter/material.dart';

class QuietHoursSection extends StatelessWidget {
  const QuietHoursSection({
    required this.quiet,
    required this.onChanged,
    super.key,
  });

  final QuietHours quiet;
  final ValueChanged<QuietHours> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        SwitchListTile(
          key: const Key('notifications_quiet_enabled'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationQuietHours),
          value: quiet.enabled,
          onChanged: (value) => onChanged(quiet.copyWith(enabled: value)),
        ),
        if (quiet.enabled)
          Row(
            children: [
              Expanded(
                child: _timeButton(
                  context,
                  label: l10n.notificationQuietStarts,
                  minutes: quiet.startMinutes,
                  onPicked: (value) =>
                      onChanged(quiet.copyWith(startMinutes: value)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _timeButton(
                  context,
                  label: l10n.notificationQuietEnds,
                  minutes: quiet.endMinutes,
                  onPicked: (value) =>
                      onChanged(quiet.copyWith(endMinutes: value)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _timeButton(
    BuildContext context, {
    required String label,
    required int minutes,
    required ValueChanged<int> onPicked,
  }) {
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return OutlinedButton(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked.hour * 60 + picked.minute);
      },
      child: Text('$label: ${time.format(context)}'),
    );
  }
}
