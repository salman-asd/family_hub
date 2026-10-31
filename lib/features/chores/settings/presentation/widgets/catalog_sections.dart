import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/presentation/chore_icons.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/catalog_editor.dart';
import 'package:family_hub/shared/widgets/color_swatch_picker.dart';
import 'package:family_hub/shared/widgets/minutes_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All three catalog editors (groups, due-time presets, absence reasons)
/// in a single widget so [ChoreSettingsScreen] stays under 300 lines (P3-17).
class CatalogSections extends ConsumerWidget {
  const CatalogSections({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final ChoreSettings draft;
  final ValueChanged<ChoreSettings> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    // Ids of templates that are using each group (for the deactivation warning).
    final templateGroupIds = ref
        .watch(templatesProvider)
        .value
        ?.map((t) => t.groupId)
        .toSet() ?? const <String>{};

    // ── Groups ─────────────────────────────────────────────────────────────
    final groupEntries = [
      for (final g in draft.groups)
        CatalogEntry(
          id: g.id,
          labelBn: g.nameBn,
          labelEn: g.nameEn,
          active: g.active,
          builtIn: g.builtIn,
          detail: l10n.choresGroupColor,
          extra: g,
        ),
    ];

    // ── Due-time presets ───────────────────────────────────────────────────
    final presetEntries = [
      for (final p in draft.dueTimePresets)
        CatalogEntry(
          id: p.id,
          labelBn: p.labelBn,
          labelEn: p.labelEn,
          active: p.active,
          builtIn: p.builtIn,
          detail: formatters.timeOfDay(p.minutes),
          extra: p,
        ),
    ];

    // ── Absence reasons ────────────────────────────────────────────────────
    final reasonEntries = [
      for (final r in draft.absenceReasons)
        CatalogEntry(
          id: r.id,
          labelBn: r.labelBn,
          labelEn: r.labelEn,
          active: r.active,
          builtIn: r.builtIn,
          extra: r,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Groups
          CatalogEditor(
            key: const ValueKey('groups-catalog'),
            title: l10n.choresSettingsGroupsTitle,
            entries: groupEntries,
            addLabel: l10n.catalogAddItem,
            onEditEntry: (ctx, entry) => _editGroup(ctx, entry, draft),
            onBeforeToggleActive: (ctx, entry) =>
                _confirmGroupDeactivate(ctx, entry, templateGroupIds),
            onChanged: (entries) => onChanged(
              draft.copyWith(groups: _groupsFrom(entries, draft.groups)),
            ),
          ),
          const SizedBox(height: 20),

          // Due-time presets
          CatalogEditor(
            key: const ValueKey('presets-catalog'),
            title: l10n.choresSettingsPresetsTitle,
            entries: presetEntries,
            addLabel: l10n.catalogAddItem,
            onEditEntry: (ctx, entry) => _editPreset(ctx, entry, formatters),
            onChanged: (entries) => onChanged(
              draft.copyWith(
                dueTimePresets: _presetsFrom(entries, draft.dueTimePresets),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Absence reasons
          CatalogEditor(
            key: const ValueKey('reasons-catalog'),
            title: l10n.choresSettingsAbsenceReasonsTitle,
            entries: reasonEntries,
            addLabel: l10n.catalogAddItem,
            onChanged: (entries) => onChanged(
              draft.copyWith(
                absenceReasons:
                    _reasonsFrom(entries, draft.absenceReasons),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Group helpers ──────────────────────────────────────────────────────────

  Future<CatalogEntry?> _editGroup(
    BuildContext context,
    CatalogEntry? existing,
    ChoreSettings draft,
  ) async {
    final current = existing?.extra is ChoreGroup
        ? existing!.extra! as ChoreGroup
        : null;
    final result = await showDialog<_GroupDraft>(
      context: context,
      builder: (ctx) => _GroupEditorDialog(existing: current),
    );
    if (result == null) return null;

    final id = existing?.id ?? _nextGroupId(draft.groups);
    final group = ChoreGroup(
      id: id,
      nameBn: result.nameBn,
      nameEn: result.nameEn.isEmpty ? null : result.nameEn,
      colorIndex: result.colorIndex,
      iconKey: result.iconKey,
      builtIn: existing?.builtIn ?? false,
      active: existing?.active ?? true,
      sortOrder: draft.groups.length,
    );
    return CatalogEntry(
      id: id,
      labelBn: group.nameBn,
      labelEn: group.nameEn,
      active: group.active,
      builtIn: group.builtIn,
      detail: context.l10n.choresGroupColor,
      extra: group,
    );
  }

  String _nextGroupId(List<ChoreGroup> groups) {
    final used = groups.map((g) => g.id).toSet();
    var n = 1;
    while (used.contains('custom_$n')) {
      n++;
    }
    return 'custom_$n';
  }

  List<ChoreGroup> _groupsFrom(
    List<CatalogEntry> entries,
    List<ChoreGroup> originals,
  ) {
    final byId = {for (final g in originals) g.id: g};
    return [
      for (var i = 0; i < entries.length; i++)
        () {
          final e = entries[i];
          if (e.extra is ChoreGroup) {
            return (e.extra! as ChoreGroup).copyWith(
              active: e.active,
              sortOrder: i,
            );
          }
          final old = byId[e.id];
          if (old != null) return old.copyWith(active: e.active, sortOrder: i);
          return ChoreGroup(id: e.id, nameBn: e.labelBn, sortOrder: i);
        }(),
    ];
  }

  Future<bool> _confirmGroupDeactivate(
    BuildContext context,
    CatalogEntry entry,
    Set<String> templateGroupIds,
  ) async {
    if (!entry.active) return true; // re-activating is always fine
    if (!templateGroupIds.contains(entry.id)) return true;
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.choresSettingsResetConfirmTitle),
        content: Text(l10n.choresSettingsResetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Preset helpers ─────────────────────────────────────────────────────────

  Future<CatalogEntry?> _editPreset(
    BuildContext context,
    CatalogEntry? existing,
    AppFormatters formatters,
  ) async {
    final current = existing?.extra is DueTimePreset
        ? existing!.extra! as DueTimePreset
        : null;
    final result = await showDialog<_PresetDraft>(
      context: context,
      builder: (ctx) => _PresetEditorDialog(existing: current, formatters: formatters),
    );
    if (result == null) return null;

    final id = existing?.id ?? _nextPresetId();
    final preset = DueTimePreset(
      id: id,
      labelBn: result.labelBn,
      labelEn: result.labelEn.isEmpty ? null : result.labelEn,
      minutes: result.minutes,
      builtIn: existing?.builtIn ?? false,
      active: existing?.active ?? true,
    );
    return CatalogEntry(
      id: id,
      labelBn: preset.labelBn,
      labelEn: preset.labelEn,
      active: preset.active,
      builtIn: preset.builtIn,
      detail: formatters.timeOfDay(preset.minutes),
      extra: preset,
    );
  }

  String _nextPresetId() => 'preset_${DateTime.now().millisecondsSinceEpoch}';

  List<DueTimePreset> _presetsFrom(
    List<CatalogEntry> entries,
    List<DueTimePreset> originals,
  ) {
    final byId = {for (final p in originals) p.id: p};
    return [
      for (final e in entries)
        if (e.extra is DueTimePreset)
          (e.extra! as DueTimePreset).copyWith(active: e.active)
        else if (byId[e.id] != null)
          byId[e.id]!.copyWith(active: e.active)
        else
          DueTimePreset(id: e.id, labelBn: e.labelBn, minutes: 540),
    ];
  }

  // ── Absence reason helpers ─────────────────────────────────────────────────

  List<AbsenceReason> _reasonsFrom(
    List<CatalogEntry> entries,
    List<AbsenceReason> originals,
  ) {
    final byId = {for (final r in originals) r.id: r};
    return [
      for (final e in entries)
        if (byId[e.id] != null)
          byId[e.id]!.copyWith(
            labelBn: e.labelBn,
            labelEn: e.labelEn,
            active: e.active,
          )
        else
          AbsenceReason(id: e.id, labelBn: e.labelBn, active: e.active),
    ];
  }
}

// ── Group editor dialog ────────────────────────────────────────────────────────

class _GroupDraft {
  const _GroupDraft({
    required this.nameBn,
    required this.nameEn,
    required this.colorIndex,
    required this.iconKey,
  });
  final String nameBn;
  final String nameEn;
  final int colorIndex;
  final String iconKey;
}

class _GroupEditorDialog extends StatefulWidget {
  const _GroupEditorDialog({this.existing});
  final ChoreGroup? existing;

  @override
  State<_GroupEditorDialog> createState() => _GroupEditorDialogState();
}

class _GroupEditorDialogState extends State<_GroupEditorDialog> {
  late final TextEditingController _nameBn;
  late final TextEditingController _nameEn;
  late int _colorIndex;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameBn = TextEditingController(text: g?.nameBn ?? '');
    _nameEn = TextEditingController(text: g?.nameEn ?? '');
    _colorIndex = g?.colorIndex ?? 0;
    _iconKey = g?.iconKey ?? 'other';
  }

  @override
  void dispose() {
    _nameBn.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(
        widget.existing == null
            ? l10n.catalogEditorAddTitle
            : l10n.catalogEditorEditTitle,
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameBn,
            decoration: InputDecoration(labelText: l10n.catalogEditorLabelBn),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameEn,
            decoration: InputDecoration(labelText: l10n.catalogEditorLabelEn),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.choresGroupColor,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ColorSwatchPicker(
            selectedIndex: _colorIndex,
            onChanged: (i) => setState(() => _colorIndex = i),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.choresGroupIcon,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          _IconPicker(
            selected: _iconKey,
            onChanged: (k) => setState(() => _iconKey = k),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () {
            final bn = _nameBn.text.trim();
            if (bn.isEmpty) return;
            Navigator.pop(
              context,
              _GroupDraft(
                nameBn: bn,
                nameEn: _nameEn.text.trim(),
                colorIndex: _colorIndex,
                iconKey: _iconKey,
              ),
            );
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

/// A compact wrap of icon chips for picking a chore group icon.
class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final key in knownIconKeys)
          Tooltip(
            message: key,
            child: InkResponse(
              onTap: () => onChanged(key),
              radius: 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: key == selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: key == selected ? 2.5 : 1,
                  ),
                ),
                child: Icon(
                  choreIcon(key),
                  size: 22,
                  color: key == selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Preset editor dialog ───────────────────────────────────────────────────────

class _PresetDraft {
  const _PresetDraft({
    required this.labelBn,
    required this.labelEn,
    required this.minutes,
  });
  final String labelBn;
  final String labelEn;
  final int minutes;
}

class _PresetEditorDialog extends StatefulWidget {
  const _PresetEditorDialog({
    this.existing,
    required this.formatters,
  });
  final DueTimePreset? existing;
  final AppFormatters formatters;

  @override
  State<_PresetEditorDialog> createState() => _PresetEditorDialogState();
}

class _PresetEditorDialogState extends State<_PresetEditorDialog> {
  late final TextEditingController _labelBn;
  late final TextEditingController _labelEn;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _labelBn = TextEditingController(text: p?.labelBn ?? '');
    _labelEn = TextEditingController(text: p?.labelEn ?? '');
    _minutes = p?.minutes ?? 540;
  }

  @override
  void dispose() {
    _labelBn.dispose();
    _labelEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(
        widget.existing == null
            ? l10n.catalogEditorAddTitle
            : l10n.catalogEditorEditTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _labelBn,
            decoration: InputDecoration(labelText: l10n.catalogEditorLabelBn),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelEn,
            decoration: InputDecoration(labelText: l10n.catalogEditorLabelEn),
          ),
          const SizedBox(height: 16),
          MinutesField(
            key: const ValueKey('preset-minutes'),
            label: l10n.choresSettingsPresetsTitle,
            minutes: _minutes,
            formatters: widget.formatters,
            clearable: false,
            onChanged: (m) => setState(() => _minutes = m ?? 540),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () {
            final bn = _labelBn.text.trim();
            if (bn.isEmpty) return;
            Navigator.pop(
              context,
              _PresetDraft(
                labelBn: bn,
                labelEn: _labelEn.text.trim(),
                minutes: _minutes,
              ),
            );
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

