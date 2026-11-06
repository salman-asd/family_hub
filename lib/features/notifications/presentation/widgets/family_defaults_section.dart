import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/notifications/domain/notification_defaults.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/features/notifications/presentation/widgets/quiet_hours_section.dart';
import 'package:family_hub/features/notifications/presentation/widgets/summary_section.dart';
import 'package:family_hub/features/notifications/presentation/widgets/timings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyDefaultsSection extends ConsumerStatefulWidget {
  const FamilyDefaultsSection({
    required this.defaults,
    required this.busy,
    required this.onSave,
    super.key,
  });

  final NotificationDefaults defaults;
  final bool busy;
  final ValueChanged<NotificationDefaults> onSave;

  @override
  ConsumerState<FamilyDefaultsSection> createState() =>
      _FamilyDefaultsSectionState();
}

class _FamilyDefaultsSectionState extends ConsumerState<FamilyDefaultsSection> {
  late NotificationDefaults _draft = widget.defaults;

  @override
  void didUpdateWidget(covariant FamilyDefaultsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaults != widget.defaults) _draft = widget.defaults;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpansionTile(
      key: const Key('family_notification_defaults'),
      title: Text(l10n.notificationFamilyDefaults),
      children: [
        SwitchListTile(
          title: Text(l10n.notificationAllEnabled),
          value: _draft.enabled,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(enabled: value)),
        ),
        SwitchListTile(
          title: Text(l10n.notificationCategoryChores),
          value: _draft.chores,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(chores: value)),
        ),
        SwitchListTile(
          title: Text(l10n.notificationCategoryBazar),
          value: _draft.bazar,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(bazar: value)),
        ),
        SwitchListTile(
          title: Text(l10n.notificationCategoryFamily),
          value: _draft.family,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(family: value)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TimingsSection(
            settings: _draft.toReminderSettings(),
            formatters: ref.watch(appFormattersProvider),
            onChanged: (next) => setState(
              () => _draft = _draft.copyWith(
                defaultOffsetsMinutes: next.defaultOffsetsMinutes,
                overdueEnabled: next.overdueEnabled,
                overdueAfterMinutes: next.overdueAfterMinutes,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SummarySection(
            summary: _draft.toReminderSettings().morningSummary,
            onChanged: (next) => setState(
              () => _draft = _draft.copyWith(
                morningSummaryEnabled: next.enabled,
                morningSummaryMinutes: next.minutes,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: QuietHoursSection(
            quiet: _draft.toReminderSettings().quiet,
            onChanged: (next) => setState(
              () => _draft = _draft.copyWith(
                quietEnabled: next.enabled,
                quietStartMinutes: next.startMinutes,
                quietEndMinutes: next.endMinutes,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: BusyButton(
            label: l10n.actionSave,
            busy: widget.busy,
            onPressed: () => widget.onSave(_draft),
          ),
        ),
      ],
    );
  }
}
