import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/templates/domain/template_saved.dart';
import 'package:family_hub/features/chores/templates/presentation/template_editor_controller.dart';
import 'package:family_hub/features/chores/templates/presentation/template_editor_state.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/assignee_editor.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/editor_basics_section.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/editor_options_section.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/editor_schedule_section.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/editor_section_card.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/instructions_editor.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/replan_scope_dialog.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/subtasks_editor.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'template_editor_screen_parts.dart';

/// Creates or edits one chore template (P3-16). [templateId] is null for a new
/// one (route `templates/new`).
///
/// Six sections (Basics, Schedule, Who, Steps, Instructions, Options) and one
/// sticky Save bar. Editing an existing chore first asks what to do with chores
/// that are already planned (see [showReplanScopeDialog]). A content save is
/// never rolled back when the follow-up planning fails: the screen then shows a
/// banner with Retry. Leaving with unsaved edits asks first.
class TemplateEditorScreen extends ConsumerWidget {
  const TemplateEditorScreen({this.templateId, super.key});

  final String? templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title = templateId == null
        ? l10n.choreEditorTitleNew
        : l10n.choreEditorTitleEdit;

    if (!ref.can(Permission.manageChoreTemplates)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.choreTemplatesNotAllowed,
        ),
      );
    }

    if (templateId != null) {
      // The controller reads the template once when it is created, so wait
      // for the first snapshot; otherwise it would start from an empty draft.
      final stream = ref.watch(templatesStreamProvider);
      if (!stream.hasValue) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const LoadingView(),
        );
      }
      if (ref.watch(templateProvider(templateId!)) == null) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: EmptyState(
            icon: Icons.search_off_rounded,
            title: l10n.choreEditorNotFound,
          ),
        );
      }
    }
    return _EditorBody(templateId: templateId, title: title);
  }
}

class _EditorBody extends ConsumerWidget {
  const _EditorBody({required this.templateId, required this.title});

  final String? templateId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = templateEditorProvider(templateId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final enabled = !state.saving && !state.archived;
    final error = state.fieldError;

    String? errorFor(Set<String> fields) =>
        error != null && fields.contains(error.field)
        ? l10n.choresFailureMessage(error)
        : null;

    Future<void> save() async {
      var scope = ReplanScope.futureOnly;
      if (!state.isNew) {
        final chosen = await showReplanScopeDialog(context);
        if (chosen == null) return;
        scope = chosen;
      }
      final status = await controller.save(replanScope: scope);
      if (status == TemplateSaveStatus.saved && context.mounted) {
        Navigator.of(context).pop();
      }
    }

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (state.archived)
              _Banner(
                icon: Icons.archive_outlined,
                message: l10n.choreEditorArchivedNote,
              ),
            if (state.status == TemplateSaveStatus.planningFailed)
              _Banner(
                icon: Icons.sync_problem_rounded,
                message: l10n.choreEditorPlanningFailed,
                actionKey: const ValueKey<String>('planning_retry'),
                actionLabel: l10n.actionRetry,
                onAction: state.saving ? null : controller.retryPlanning,
              ),
            EditorSectionCard(
              title: l10n.choreEditorSectionBasics,
              error: errorFor(const {
                'nameBn',
                'nameEn',
                'colorIndex',
                'iconKey',
              }),
              child: EditorBasicsSection(
                draft: state.draft,
                controller: controller,
                enabled: enabled,
              ),
            ),
            EditorSectionCard(
              title: l10n.choreEditorSectionSchedule,
              error: errorFor(const {'slots', 'endDate', 'recurrence'}),
              child: EditorScheduleSection(
                draft: state.draft,
                controller: controller,
                enabled: enabled,
              ),
            ),
            EditorSectionCard(
              title: l10n.choreEditorSectionWho,
              error: errorFor(const {'assignee'}),
              child: AssigneeEditor(
                assignee: state.draft.assignee,
                enabled: enabled,
                onChanged: controller.setAssignee,
              ),
            ),
            EditorSectionCard(
              title: l10n.choreEditorSectionSteps,
              error: errorFor(const {'subtasks'}),
              child: SubtasksEditor(
                subtasks: state.draft.subtasks,
                enabled: enabled,
                onChanged: controller.setSubtasks,
              ),
            ),
            EditorSectionCard(
              title: l10n.choreEditorSectionInstructions,
              error: errorFor(const {'instructions'}),
              child: InstructionsEditor(
                value: state.draft.instructions,
                enabled: enabled,
                onChanged: controller.setInstructions,
              ),
            ),
            EditorSectionCard(
              title: l10n.choreEditorSectionOptions,
              error: errorFor(const {'estimatedMinutes', 'reminders'}),
              child: EditorOptionsSection(
                draft: state.draft,
                active: state.active,
                controller: controller,
                enabled: enabled,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _SaveBar(
          failure: state.saveFailure,
          saving: state.saving,
          // A new chore can always be saved (an empty one is reported by the
          // validator); an existing one only when something changed.
          canSave: !state.cannotSave && (state.isNew || state.isDirty),
          onSave: save,
        ),
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
