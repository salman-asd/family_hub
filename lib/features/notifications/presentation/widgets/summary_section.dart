import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/notifications/domain/reminder_settings.dart';
import 'package:flutter/material.dart';

class SummarySection extends StatelessWidget {
  const SummarySection({
    required this.summary,
    required this.onChanged,
    super.key,
  });

  final MorningSummary summary;
  final ValueChanged<MorningSummary> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = TimeOfDay(
      hour: summary.minutes ~/ 60,
      minute: summary.minutes % 60,
    );
    return Column(
      children: [
        SwitchListTile(
          key: const Key('notifications_summary'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationMorningSummary),
          value: summary.enabled,
          onChanged: (value) => onChanged(summary.copyWith(enabled: value)),
        ),
        if (summary.enabled)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) {
                  onChanged(
                    summary.copyWith(minutes: picked.hour * 60 + picked.minute),
                  );
                }
              },
              child: Text(l10n.notificationSummaryTime(time.format(context))),
            ),
          ),
      ],
    );
  }
}
