import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/locale_controller.dart';
import 'package:family_hub/core/notifications/domain/reminder_explainer.dart';
import 'package:family_hub/core/notifications/domain/notification_type.dart';
import 'package:family_hub/core/notifications/domain/reminder_precedence.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/chores/presentation/plannable_chore_mapper.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/notifications/presentation/notification_providers.dart';
import 'package:family_hub/features/notifications/presentation/reminder_texts.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReminderWhyLine extends ConsumerWidget {
  const ReminderWhyLine({required this.item, super.key});

  final ChoreItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final uid = ref.watch(currentUidProvider);
    if (!settings.hasValue || uid == null) return const SizedBox.shrink();
    final locale = ref.watch(localeControllerProvider);
    final localizations = AppLocalizations.of(context);
    final effectiveModes = <String, DeliveryMode>{};
    for (final type in NotificationTypes.all) {
      final mode = ref.watch(effectiveModeProvider(type.id));
      if (!mode.hasValue) return const SizedBox.shrink();
      effectiveModes[type.id] = mode.requireValue.mode;
    }
    final templateIndex = <String, TemplateReminderConfig>{
      for (final entry in ref.watch(templateIndexProvider).entries)
        entry.key: TemplateReminderConfig(
          enabled: entry.value.draft.reminders.enabled,
          atDue: entry.value.draft.reminders.atDue,
          offsetsMinutes: entry.value.draft.reminders.offsetsMinutes,
          overdueEnabled: entry.value.draft.reminders.overdueEnabled,
          overdueAfterMinutes: entry.value.draft.reminders.overdueAfterMinutes,
        ),
    };
    final explanation = ReminderExplainer.explain(
      item: PlannableChoreMapper.fromItem(item),
      settings: settings.requireValue,
      now: ref.watch(clockProvider).nowUtc(),
      familyTz: ref.watch(familyTimezoneProvider),
      texts: LocalizedReminderTexts(
        localizations: localizations,
        useBanglaDigits: locale.useBanglaDigits,
      ),
      viewerId: uid,
      templateIndex: templateIndex,
      effectiveModes: effectiveModes,
    );
    final label = explanation.willFire && explanation.nextAt != null
        ? localizations.reminderWhyNext(
            LocalizedReminderTexts(
              localizations: localizations,
              useBanglaDigits: locale.useBanglaDigits,
            ).formatTime(
              explanation.nextAt!,
              ref.watch(familyTimezoneProvider),
            ),
          )
        : _reasonText(localizations, explanation.reasons.first);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 8, start: 4, end: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }

  String _reasonText(
    AppLocalizations l10n,
    ReminderExplanationReason reason,
  ) => switch (reason) {
    ReminderExplanationReason.deliveredAsPush => l10n.reminderWhyPush,
    ReminderExplanationReason.globalOff => l10n.reminderWhyGlobalOff,
    ReminderExplanationReason.categoryOff => l10n.reminderWhyCategoryOff,
    ReminderExplanationReason.templateOff => l10n.reminderWhyTemplateOff,
    ReminderExplanationReason.templateNoTimings =>
      l10n.reminderWhyTemplateNoTimings,
    ReminderExplanationReason.notAssigned => l10n.reminderWhyNotAssigned,
    ReminderExplanationReason.notOpen => l10n.reminderWhyNotOpen,
    ReminderExplanationReason.unavailable => l10n.reminderWhyUnavailable,
    ReminderExplanationReason.projectedPast => l10n.reminderWhyProjectedPast,
    ReminderExplanationReason.noUpcomingReminder => l10n.reminderWhyNoUpcoming,
  };
}
