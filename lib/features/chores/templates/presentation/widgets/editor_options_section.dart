import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:family_hub/features/chores/templates/presentation/template_editor_controller.dart';
import 'package:family_hub/features/chores/templates/presentation/template_labels.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/draft_text_field.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/reminders_block.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:flutter/material.dart';

/// Section 6 of the template editor: estimated time, difficulty, verification,
/// reminders and the active switch.
class EditorOptionsSection extends StatelessWidget {
  const EditorOptionsSection({
    required this.draft,
    required this.active,
    required this.controller,
    required this.enabled,
    super.key,
  });

  final TemplateDraft draft;
  final bool active;
  final TemplateEditorController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = Theme.of(context).textTheme.labelLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DraftTextField(
          key: const ValueKey<String>('estimated_minutes'),
          value: draft.estimatedMinutes == null
              ? ''
              : '${draft.estimatedMinutes}',
          label: l10n.choreEditorEstimatedMinutes,
          keyboardType: TextInputType.number,
          enabled: enabled,
          onChanged: (text) {
            final trimmed = text.trim();
            controller.setEstimatedMinutes(
              trimmed.isEmpty ? null : int.tryParse(trimmed),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(l10n.choreEditorDifficulty, style: label),
        const SizedBox(height: 8),
        ChoiceWrap<Difficulty>(
          selected: draft.difficulty,
          onChanged: (d) {
            if (enabled) controller.setDifficulty(d);
          },
          options: [
            for (final d in Difficulty.values)
              ChoiceOption<Difficulty>(
                d,
                difficultyLabel(l10n, d),
                key: ValueKey<String>('difficulty_${d.id}'),
              ),
          ],
        ),
        SwitchListTile(
          key: const ValueKey<String>('verification_required'),
          contentPadding: EdgeInsets.zero,
          value: draft.verification == VerificationMode.required,
          title: Text(l10n.choreEditorVerification),
          subtitle: Text(l10n.choreEditorVerificationHelp),
          onChanged: enabled
              ? (v) => controller.setVerification(
                  v ? VerificationMode.required : VerificationMode.off,
                )
              : null,
        ),
        RemindersBlock(
          reminders: draft.reminders,
          enabled: enabled,
          onChanged: controller.setReminders,
        ),
        SwitchListTile(
          key: const ValueKey<String>('template_active'),
          contentPadding: EdgeInsets.zero,
          value: active,
          title: Text(l10n.choreEditorActive),
          subtitle: Text(l10n.choreEditorActiveHelp),
          onChanged: enabled ? (v) => controller.setActive(v) : null,
        ),
      ],
    );
  }
}
