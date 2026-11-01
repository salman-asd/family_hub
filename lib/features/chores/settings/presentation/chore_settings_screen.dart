import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_controller.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_state.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/calendar_defaults_section.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/catalog_sections.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/generation_section.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/house_rules_section.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/policies_section.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chore settings page (P3-17): every field of `ChoreSettings` is edited
/// here, and nothing else in the app hard-codes them (D-P3-4).
///
/// One page, five sections, ONE Save for all of them. The draft lives in
/// [ChoreSettingsController]; this widget only draws it. Saving needs the
/// server, so offline it keeps the draft and says so. Leaving with unsaved
/// edits asks first, and each section can go back to its defaults (after a
/// confirmation; templates are never deleted by it).
class ChoreSettingsScreen extends ConsumerWidget {
  const ChoreSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canManage = ref.can(Permission.manageChoreTemplates);

    // A plain member who reaches this route (a stale link) sees an explanation
    // instead of the controls; the rules refuse the write anyway.
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.choresSettingsTitle)),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.choresSettingsNotAllowed,
        ),
      );
    }

    final form = ref.watch(choreSettingsEditorProvider);
    final controller = ref.read(choreSettingsEditorProvider.notifier);

    ref.listen<bool>(
      choreSettingsEditorProvider.select((s) => s.justSaved),
      (_, saved) {
        if (saved) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.choresSettingsSaved)));
        }
      },
    );

    return PopScope(
      canPop: !form.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard(context);
        if (leave && context.mounted) {
          controller.discard();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.choresSettingsTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionCard(
              title: l10n.choresSettingsCalendarTitle,
              section: ChoreSettingsSection.calendar,
              child: CalendarDefaultsSection(
                draft: form.draft,
                onChanged: controller.setDraft,
              ),
            ),
            _SectionCard(
              title: l10n.choresSettingsGenerationTitle,
              section: ChoreSettingsSection.generation,
              child: GenerationSection(
                draft: form.draft,
                onChanged: controller.setDraft,
              ),
            ),
            _SectionCard(
              title: l10n.choresSettingsCatalogsTitle,
              section: ChoreSettingsSection.catalogs,
              child: CatalogSections(
                draft: form.draft,
                onChanged: controller.setDraft,
              ),
            ),
            _SectionCard(
              title: l10n.choresSettingsPoliciesTitle,
              section: ChoreSettingsSection.policies,
              child: PoliciesSection(
                draft: form.draft,
                policy: form.policy,
                completeForOthers: form.completeForOthers,
                onSettingsChanged: controller.setDraft,
                onPolicyChanged: controller.setPolicy,
                onCompleteForOthersChanged: (v) =>
                    controller.setCompleteForOthers(value: v),
              ),
            ),
            _SectionCard(
              title: l10n.choresSettingsHouseRulesTitle,
              section: ChoreSettingsSection.houseRules,
              child: HouseRulesSection(
                houseRules: form.draft.houseRules,
                onChanged: (text) =>
                    controller.setDraft(form.draft.copyWith(houseRules: text)),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _SaveBar(form: form, onSave: controller.save),
      ),
    );
  }

  static Future<bool> _confirmDiscard(BuildContext context) async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.choresSettingsDiscardTitle),
        content: Text(l10n.choresSettingsDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey<String>('discard_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionDiscard),
          ),
        ],
      ),
    );
    return leave ?? false;
  }
}

/// One section: its title, a "Reset section" action with a confirmation, and
/// the section widget.
class _SectionCard extends ConsumerWidget {
  const _SectionCard({
    required this.title,
    required this.section,
    required this.child,
  });

  final String title;
  final ChoreSettingsSection section;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.radiusMd),
          boxShadow: t.elevation1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: TextButton(
                key: ValueKey<String>('reset_${section.name}'),
                onPressed: () async {
                  final ok = await _confirmReset(context);
                  if (ok) {
                    ref
                        .read(choreSettingsEditorProvider.notifier)
                        .resetSection(section);
                  }
                },
                child: Text(l10n.choresSettingsResetSection),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmReset(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.choresSettingsResetConfirmTitle),
        content: Text(l10n.choresSettingsResetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey<String>('reset_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.choresSettingsResetConfirmAction),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

/// The sticky bar: the failure (or "needs internet") and the one Save button.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.form, required this.onSave});

  final ChoreSettingsFormState form;
  final Future<bool> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final failure = form.failure;
    final message = failure == null
        ? null
        : (form.needsInternet
              ? l10n.choresSettingsNeedsInternet
              : l10n.choresFailureMessage(failure));
    return Material(
      color: t.surfaceRaised,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        form.needsInternet
                            ? Icons.cloud_off_rounded
                            : Icons.error_outline_rounded,
                        size: 18,
                        color: t.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          key: const ValueKey<String>('settings_failure'),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: t.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              BusyButton(
                key: const ValueKey<String>('settings_save'),
                label: l10n.choresSettingsSave,
                busy: form.saving,
                busyLabel: l10n.loadingSemantics,
                onPressed: form.isDirty ? () => onSave() : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
