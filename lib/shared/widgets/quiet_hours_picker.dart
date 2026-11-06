import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/shared/widgets/minutes_field.dart';
import 'package:flutter/material.dart';

class QuietHoursPicker extends StatelessWidget {
  const QuietHoursPicker({
    required this.startLabel,
    required this.endLabel,
    required this.startMinutes,
    required this.endMinutes,
    required this.formatters,
    required this.onStartChanged,
    required this.onEndChanged,
    this.enabled = true,
    super.key,
  });

  final String startLabel;
  final String endLabel;
  final int startMinutes;
  final int endMinutes;
  final AppFormatters formatters;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    children: [
      SizedBox(
        width: 140,
        child: MinutesField(
          label: startLabel,
          minutes: startMinutes,
          formatters: formatters,
          clearable: false,
          enabled: enabled,
          onChanged: (value) {
            if (value != null) onStartChanged(value);
          },
        ),
      ),
      SizedBox(
        width: 140,
        child: MinutesField(
          label: endLabel,
          minutes: endMinutes,
          formatters: formatters,
          clearable: false,
          enabled: enabled,
          onChanged: (value) {
            if (value != null) onEndChanged(value);
          },
        ),
      ),
    ],
  );
}
