import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/draft_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The reminder settings of one chore (P3-16): at the due time, N minutes
/// before (up to five), and once when it is overdue.
///
/// STORED only: nothing in Phase 3 sends a notification, and the block says so.
/// Phase 4 reads these values.
class RemindersBlock extends ConsumerWidget {
  const RemindersBlock({
    required this.reminders,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final ReminderConfig reminders;
  final ValueChanged<ReminderConfig> onChanged;
  final bool enabled;

  /// The quick choices; any other value 1-1440 is typed in.
  static const List<int> quickOffsets = <int>[5, 10, 20, 30, 60];

  static const int maxOffsets = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final offsets = reminders.offsetsMinutes;
    // Offsets typed in by the user that are not one of the quick choices.
    final custom = <int>[
      for (final m in offsets)
        if (!quickOffsets.contains(m)) m,
    ];

    void toggleOffset(int minutes) {
      final next = <int>[...offsets];
      if (next.contains(minutes)) {
        next.remove(minutes);
      } else if (next.length < maxOffsets) {
        next.add(minutes);
      }
      next.sort();
      onChanged(reminders.copyWith(offsetsMinutes: next));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const ValueKey<String>('reminders_enabled'),
          contentPadding: EdgeInsets.zero,
          value: reminders.enabled,
          title: Text(l10n.choreRemindersTitle),
          subtitle: Text(l10n.choreRemindersStoredNote),
          onChanged: enabled
              ? (v) => onChanged(reminders.copyWith(enabled: v))
              : null,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey<String>('reminders_help_link'),
            onPressed: () => context.push(AppRoutes.remindersHelp),
            icon: const Icon(Icons.help_outline),
            label: Text(l10n.notificationHelpTitle),
          ),
        ),
        if (reminders.enabled) ...[
          SwitchListTile(
            key: const ValueKey<String>('reminder_at_due'),
            contentPadding: EdgeInsets.zero,
            value: reminders.atDue,
            title: Text(l10n.choreReminderAtDue),
            onChanged: enabled
                ? (v) => onChanged(reminders.copyWith(atDue: v))
                : null,
          ),
          Text(
            l10n.choreReminderBeforeTitle,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final minutes in <int>[...quickOffsets, ...custom])
                FilterChip(
                  key: ValueKey<String>('reminder_offset_$minutes'),
                  label: Text(
                    l10n.choreReminderBefore(formatters.number(minutes)),
                  ),
                  selected: offsets.contains(minutes),
                  showCheckmark: true,
                  onSelected: enabled ? (_) => toggleOffset(minutes) : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _CustomOffsetField(
            enabled: enabled && offsets.length < maxOffsets,
            onAdd: (minutes) {
              if (!offsets.contains(minutes) && offsets.length < maxOffsets) {
                final next = <int>[...offsets, minutes]..sort();
                onChanged(reminders.copyWith(offsetsMinutes: next));
              }
            },
          ),
          SwitchListTile(
            key: const ValueKey<String>('reminder_overdue'),
            contentPadding: EdgeInsets.zero,
            value: reminders.overdueEnabled,
            title: Text(l10n.choreReminderOverdue),
            onChanged: enabled
                ? (v) => onChanged(reminders.copyWith(overdueEnabled: v))
                : null,
          ),
          if (reminders.overdueEnabled)
            DraftTextField(
              key: const ValueKey<String>('reminder_overdue_after'),
              value: '${reminders.overdueAfterMinutes}',
              label: l10n.choreReminderOverdueAfter,
              keyboardType: TextInputType.number,
              enabled: enabled,
              onChanged: (text) {
                final value = int.tryParse(text.trim());
                if (value != null && value >= 1 && value <= 1440) {
                  onChanged(reminders.copyWith(overdueAfterMinutes: value));
                }
              },
            ),
        ],
      ],
    );
  }
}

/// A number field with an add button for an offset that is not a quick choice.
class _CustomOffsetField extends StatefulWidget {
  const _CustomOffsetField({required this.enabled, required this.onAdd});

  final bool enabled;
  final ValueChanged<int> onAdd;

  @override
  State<_CustomOffsetField> createState() => _CustomOffsetFieldState();
}

class _CustomOffsetFieldState extends State<_CustomOffsetField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1 || value > 1440) return;
    widget.onAdd(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey<String>('reminder_custom_field'),
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.choreReminderCustom,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _add(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey<String>('reminder_custom_add'),
          tooltip: l10n.choreReminderCustomAdd,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: widget.enabled ? _add : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
