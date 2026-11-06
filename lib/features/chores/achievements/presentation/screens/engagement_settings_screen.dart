import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/engagement_settings_form.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EngagementSettingsScreen extends ConsumerStatefulWidget {
  const EngagementSettingsScreen({super.key});

  @override
  ConsumerState<EngagementSettingsScreen> createState() =>
      _EngagementSettingsScreenState();
}

class _EngagementSettingsScreenState
    extends ConsumerState<EngagementSettingsScreen> {
  EngagementSettings? _draft;
  EngagementSettings? _saved;
  final Set<String> _invalidFields = <String>{};
  bool _saving = false;
  bool _offline = false;
  bool _confirmingBack = false;
  int _editorRevision = 0;

  bool get _dirty => _draft != null && _saved != null && _draft != _saved;

  bool get _valid {
    final value = _draft;
    if (value == null || _invalidFields.isNotEmpty) return false;
    try {
      LevelTable(value.levels);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  void _edit(EngagementSettings value) {
    setState(() {
      _draft = value;
      _offline = false;
    });
  }

  void _fieldValidity(String id, bool valid) {
    setState(() {
      if (valid) {
        _invalidFields.remove(id);
      } else {
        _invalidFields.add(id);
      }
    });
  }

  Future<void> _save(String familyId, String actorUid) async {
    final previous = _saved;
    final updated = _draft;
    if (_saving || !_valid || previous == null || updated == null) return;
    setState(() {
      _saving = true;
      _offline = false;
    });
    final today = ref.read(familyDateKeysProvider).today();
    final result = await ref
        .read(updateEngagementSettingsProvider)
        .call(
          actorUid: actorUid,
          familyId: familyId,
          previous: previous,
          updated: updated,
          today: today,
        );
    if (!mounted) return;
    final saved = result.valueOrNull;
    setState(() {
      _saving = false;
      if (saved != null) {
        _saved = saved;
        _draft = saved;
        _invalidFields.clear();
      } else {
        _offline = result.failureOrNull is Network;
      }
    });
    if (saved != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.engagementSettingsSaved)),
        );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _offline
                ? context.l10n.engagementSettingsOffline
                : context.l10n.engagementSettingsSaveFailed,
          ),
        ),
      );
    }
  }

  Future<void> _changeVisibility(StatsVisibility visibility) async {
    final draft = _draft;
    if (draft == null || draft.statsVisibility == visibility) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.engagementSettingsVisibilityConfirmTitle),
        content: Text(l10n.engagementSettingsVisibilityConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _edit(draft.copyWith(statsVisibility: visibility));
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.engagementSettingsDiscardTitle),
            content: Text(l10n.engagementSettingsDiscardMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.actionDiscard),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final familyId = ref.watch(currentFamilyIdProvider);
    final actorUid = ref.watch(currentUidProvider);
    final canManage = ref.can(Permission.manageEngagement);
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.engagementSettingsGeneral)),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.engagementSettingsNotAllowed,
        ),
      );
    }
    if (familyId == null || actorUid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.engagementSettingsGeneral)),
        body: const LoadingView(),
      );
    }
    final remote = ref.watch(engagementSettingsProvider(familyId));
    if (!remote.hasValue && remote.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.engagementSettingsGeneral)),
        body: ErrorView(
          message: l10n.errorNetwork,
          onRetry: () => ref.invalidate(engagementSettingsProvider(familyId)),
        ),
      );
    }
    if (!remote.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.engagementSettingsGeneral)),
        body: const LoadingView(),
      );
    }
    final current = remote.requireValue;
    if (_saved != current) {
      final hadChanges = _dirty;
      _saved = current;
      if (!hadChanges) _draft = current;
    }
    final draft = _draft ?? current;
    final defaults = defaultEngagementSettings(
      startedOn: draft.startedOn,
      graceMinutes: ref.watch(choreSettingsProvider).overdueGraceMinutes,
    );
    final canEditVisibility = ref.can(Permission.editFamilySettings);
    final number = ref.watch(appFormattersProvider).number;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_dirty || _confirmingBack) return;
        _confirmingBack = true;
        final discard = await _confirmDiscard();
        _confirmingBack = false;
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.engagementSettingsGeneral)),
        body: EngagementSettingsForm(
          settings: draft,
          defaults: defaults,
          offline: _offline,
          valid: _valid,
          editorRevision: _editorRevision,
          canEditVisibility: canEditVisibility,
          number: number,
          onChanged: _edit,
          onValidityChanged: _fieldValidity,
          onInvalidatedLevels: () => setState(_invalidFields.clear),
          onVisibilityChanged: _changeVisibility,
          onResetLevels: () {
            setState(() {
              _invalidFields.clear();
              _editorRevision++;
              _draft = draft.copyWith(levels: defaults.levels);
            });
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: BusyButton(
            key: const Key('engagement_settings_save'),
            label: l10n.actionSave,
            busy: _saving,
            onPressed: _dirty && _valid && !_saving
                ? () => _save(familyId, actorUid)
                : null,
          ),
        ),
      ),
    );
  }
}
