import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/duty_groups/domain/rotation_draft.dart';
import 'package:family_hub/features/chores/duty_groups/presentation/duty_group_labels.dart';
import 'package:family_hub/features/chores/duty_groups/presentation/duty_group_providers.dart';
import 'package:family_hub/features/chores/duty_groups/presentation/widgets/rotation_editor.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/features/chores/templates/presentation/template_labels.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who does the chore (P3-16): a rotation, one fixed person, or nobody until a
/// manager assigns it.
///
/// A rotation is either an existing DUTY GROUP (picked from
/// `dutyGroupsProvider`, so the rota is edited in one place) or the chore's OWN
/// rotation, edited here with the same [RotationEditor] the duty-group screens
/// use. Choosing one clears the other, so a template never carries both.
///
/// Editing an own rotation writes a new FIRST version: that is right for a new
/// chore; for a stored one it replaces the rota from the chosen start day on,
/// which is why a rota that changes over time belongs in a duty group (whose
/// changes are versioned).
class AssigneeEditor extends ConsumerStatefulWidget {
  const AssigneeEditor({
    required this.assignee,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final AssigneeSpec assignee;
  final ValueChanged<AssigneeSpec> onChanged;
  final bool enabled;

  @override
  ConsumerState<AssigneeEditor> createState() => _AssigneeEditorState();
}

enum _RotationSource { group, own }

class _AssigneeEditorState extends ConsumerState<AssigneeEditor> {
  late _RotationSource _source =
      widget.assignee.rotation != null && widget.assignee.dutyGroupId == null
      ? _RotationSource.own
      : _RotationSource.group;
  RotationDraft? _draft;

  RotationDraft _currentDraft() {
    final existing = _draft;
    if (existing != null) return existing;
    final rotation = widget.assignee.rotation;
    final version = rotation == null || rotation.versions.isEmpty
        ? null
        : rotation.versions.last;
    if (version != null) {
      return RotationDraft(
        members: version.members,
        startsWith: version.members.isEmpty
            ? null
            : version.members[version.anchorIndex
                  .clamp(0, version.members.length - 1)
                  .toInt()],
        startsOn: version.anchorDate,
        cycleUnit: version.cycleUnit,
        weekStartDay: version.weekStartDay,
      );
    }
    return RotationDraft(
      members: const <String>[],
      startsOn: ref.read(familyDateKeysProvider).today(),
      cycleUnit: CycleUnit.week,
      weekStartDay: ref.read(choreSettingsProvider).weekStartDay,
    );
  }

  void _setStrategy(AssigneeStrategy strategy) {
    switch (strategy) {
      case AssigneeStrategy.manual:
        widget.onChanged(const AssigneeSpec(strategy: AssigneeStrategy.manual));
      case AssigneeStrategy.fixed:
        widget.onChanged(const AssigneeSpec(strategy: AssigneeStrategy.fixed));
      case AssigneeStrategy.rotation:
        final groups = ref.read(activeDutyGroupsProvider);
        _source = _RotationSource.group;
        widget.onChanged(
          AssigneeSpec(
            strategy: AssigneeStrategy.rotation,
            dutyGroupId: groups.isEmpty ? null : groups.first.id,
          ),
        );
    }
  }

  void _setSource(_RotationSource source) {
    setState(() => _source = source);
    if (source == _RotationSource.group) {
      final groups = ref.read(activeDutyGroupsProvider);
      widget.onChanged(
        AssigneeSpec(
          strategy: AssigneeStrategy.rotation,
          dutyGroupId: groups.isEmpty ? null : groups.first.id,
        ),
      );
    } else {
      _applyDraft(_currentDraft());
    }
  }

  void _applyDraft(RotationDraft draft) {
    setState(() => _draft = draft);
    // Fewer than two people is not a rotation yet: the spec carries no
    // rotation and the validator reports it on save.
    final rotation = draft.toRotation().valueOrNull;
    widget.onChanged(
      AssigneeSpec(strategy: AssigneeStrategy.rotation, rotation: rotation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final spec = widget.assignee;
    final label = Theme.of(context).textTheme.labelLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceWrap<AssigneeStrategy>(
          selected: spec.strategy,
          onChanged: (s) {
            if (widget.enabled) _setStrategy(s);
          },
          options: [
            for (final strategy in AssigneeStrategy.values)
              ChoiceOption<AssigneeStrategy>(
                strategy,
                strategyLabel(l10n, strategy),
                key: ValueKey<String>('strategy_${strategy.id}'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        switch (spec.strategy) {
          AssigneeStrategy.manual => Text(
            l10n.choreAssigneeManualHelp,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
          ),
          AssigneeStrategy.fixed => PersonPicker(
            label: l10n.choreAssigneeFixedLabel,
            options: [
              for (final member in ref.watch(dutyRosterProvider))
                PersonOption(
                  id: member.uid,
                  name: member.displayName,
                  avatarKey: member.avatarKey,
                ),
            ],
            selectedId: spec.fixedMemberId,
            onChanged: (id) {
              if (!widget.enabled || id == null) return;
              widget.onChanged(
                AssigneeSpec(
                  strategy: AssigneeStrategy.fixed,
                  fixedMemberId: id,
                ),
              );
            },
          ),
          AssigneeStrategy.rotation => _rotation(context, label),
        },
      ],
    );
  }

  Widget _rotation(BuildContext context, TextStyle? label) {
    final l10n = context.l10n;
    final groups = ref.watch(activeDutyGroupsProvider);
    final spec = widget.assignee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceWrap<_RotationSource>(
          selected: _source,
          onChanged: (s) {
            if (widget.enabled) _setSource(s);
          },
          options: [
            ChoiceOption<_RotationSource>(
              _RotationSource.group,
              l10n.choreAssigneeSourceGroup,
              key: const ValueKey<String>('source_group'),
            ),
            ChoiceOption<_RotationSource>(
              _RotationSource.own,
              l10n.choreAssigneeSourceOwn,
              key: const ValueKey<String>('source_own'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_source == _RotationSource.group) ...[
          if (groups.isEmpty)
            Text(l10n.choreAssigneeNoGroups)
          else ...[
            Text(l10n.choreAssigneePickGroup, style: label),
            const SizedBox(height: 4),
            ChoiceWrap<String>(
              selected: spec.dutyGroupId,
              onChanged: (id) {
                if (!widget.enabled) return;
                widget.onChanged(
                  AssigneeSpec(
                    strategy: AssigneeStrategy.rotation,
                    dutyGroupId: id,
                  ),
                );
              },
              options: [
                for (final group in groups)
                  ChoiceOption<String>(
                    group.id,
                    dutyGroupName(context, group),
                    key: ValueKey<String>('group_${group.id}'),
                  ),
              ],
            ),
          ],
        ] else
          RotationEditor(
            draft: _currentDraft(),
            enabled: widget.enabled,
            onChanged: _applyDraft,
          ),
      ],
    );
  }
}
