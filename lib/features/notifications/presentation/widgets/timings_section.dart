import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/notifications/domain/reminder_settings.dart';
import 'package:flutter/material.dart';

class TimingsSection extends StatefulWidget {
  const TimingsSection({
    required this.settings,
    required this.formatters,
    required this.onChanged,
    super.key,
  });

  static const _quickOffsets = <int>[5, 10, 20, 30, 60];

  final ReminderSettings settings;
  final AppFormatters formatters;
  final ValueChanged<ReminderSettings> onChanged;

  @override
  State<TimingsSection> createState() => _TimingsSectionState();
}

class _TimingsSectionState extends State<TimingsSection> {
  final _customOffset = TextEditingController();
  bool _invalidOffset = false;

  @override
  void dispose() {
    _customOffset.dispose();
    super.dispose();
  }

  void _addCustomOffset() {
    final value = int.tryParse(_customOffset.text.trim());
    final offsets = widget.settings.defaultOffsetsMinutes;
    if (value == null ||
        value < 1 ||
        value > 1440 ||
        offsets.contains(value) ||
        offsets.length >= 5) {
      setState(() => _invalidOffset = true);
      return;
    }
    final next = [...offsets, value]..sort();
    widget.onChanged(widget.settings.copyWith(defaultOffsetsMinutes: next));
    setState(() => _invalidOffset = false);
    _customOffset.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = widget.settings;
    final offsets = settings.defaultOffsetsMinutes;
    final customOffsets = offsets.where(
      (offset) => !TimingsSection._quickOffsets.contains(offset),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.notificationDefaultOffsets),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final offset in [
              ...TimingsSection._quickOffsets,
              ...customOffsets,
            ])
              FilterChip(
                key: Key('notification_offset_$offset'),
                label: Text(
                  l10n.choreReminderBefore(widget.formatters.number(offset)),
                ),
                selected: offsets.contains(offset),
                onSelected: offsets.length >= 5 && !offsets.contains(offset)
                    ? null
                    : (selected) {
                        final next = [...offsets];
                        if (selected) {
                          next.add(offset);
                        } else {
                          next.remove(offset);
                        }
                        next.sort();
                        widget.onChanged(
                          settings.copyWith(defaultOffsetsMinutes: next),
                        );
                      },
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('notification_custom_offset'),
                controller: _customOffset,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.notificationCustomOffset,
                  errorText: _invalidOffset
                      ? l10n.notificationInvalidOffset
                      : null,
                ),
                onSubmitted: (_) => _addCustomOffset(),
              ),
            ),
            IconButton.filledTonal(
              tooltip: l10n.notificationAddOffset,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: offsets.length >= 5 ? null : _addCustomOffset,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        SwitchListTile(
          key: const Key('notifications_overdue'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationOverdue),
          value: settings.overdueEnabled,
          onChanged: (value) =>
              widget.onChanged(settings.copyWith(overdueEnabled: value)),
        ),
      ],
    );
  }
}
