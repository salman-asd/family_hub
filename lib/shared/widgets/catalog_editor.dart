import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/catalog_entry_dialog.dart';
import 'package:flutter/material.dart';

/// One editable row of a [CatalogEditor].
///
/// The same shape serves chore groups, due-time presets and absence reasons
/// (road map 3.2), so P3-17 edits three lists with one widget instead of three
/// near-identical screens.
@immutable
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.labelBn,
    this.labelEn,
    this.active = true,
    this.builtIn = false,
    this.detail,
  });

  /// Stable machine id (`kitchen`, `morning`, …). Never shown.
  final String id;

  final String labelBn;
  final String? labelEn;

  /// Inactive rows stay in the list but are no longer offered as a choice.
  final bool active;

  /// Built-in rows can be edited and deactivated, never deleted (they come
  /// from the starter pack and the recurrence code may reference them).
  final bool builtIn;

  /// A short secondary line (for a preset: the time; for a group: the colour).
  /// Already formatted by the caller.
  final String? detail;

  CatalogEntry copyWith({
    String? labelBn,
    String? labelEn,
    bool? active,
    String? detail,
  }) => CatalogEntry(
    id: id,
    labelBn: labelBn ?? this.labelBn,
    labelEn: labelEn ?? this.labelEn,
    active: active ?? this.active,
    builtIn: builtIn,
    detail: detail ?? this.detail,
  );

  @override
  bool operator ==(Object other) =>
      other is CatalogEntry &&
      other.id == id &&
      other.labelBn == labelBn &&
      other.labelEn == labelEn &&
      other.active == active &&
      other.builtIn == builtIn &&
      other.detail == detail;

  @override
  int get hashCode =>
      Object.hash(id, labelBn, labelEn, active, builtIn, detail);
}

/// Reorderable, add/edit/deactivate list of [CatalogEntry] rows (P3-04).
///
/// The editor is a pure view: it holds no state and never writes anywhere. It
/// reports the WHOLE new list through [onChanged] for every action (reorder,
/// add, rename, deactivate), so the caller keeps one list and one use case.
/// Rows are drag handles plus an action menu; every action target is 48 dp.
class CatalogEditor extends StatelessWidget {
  const CatalogEditor({
    required this.entries,
    required this.onChanged,
    this.title,
    this.addLabel,
    this.emptyLabel,
    this.canReorder = true,
    super.key,
  });

  final List<CatalogEntry> entries;

  /// Called with the full new list after every action.
  final ValueChanged<List<CatalogEntry>> onChanged;

  final String? title;

  /// Label of the add button; defaults to the localized "Add".
  final String? addLabel;

  /// Shown when the list is empty.
  final String? emptyLabel;

  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(title!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
        ],
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              emptyLabel ?? l10n.catalogEditorEmpty,
              style: TextStyle(color: tokens.textSecondary),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: entries.length,
            // `onReorderItem` already reports the final index of the moved row
            // (the deprecated `onReorder` did not), so no off-by-one shift.
            onReorderItem: (oldIndex, newIndex) {
              final next = <CatalogEntry>[...entries];
              final moved = next.removeAt(oldIndex);
              next.insert(newIndex, moved);
              onChanged(next);
            },
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _Row(
                key: ValueKey<String>(entry.id),
                entry: entry,
                index: index,
                showHandle: canReorder,
                onEdit: () => _edit(context, entry),
                onToggleActive: () =>
                    _replace(entry, entry.copyWith(active: !entry.active)),
                onDelete: entry.builtIn ? null : () => _remove(entry),
              );
            },
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => _add(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(addLabel ?? l10n.actionAdd),
          ),
        ),
      ],
    );
  }

  void _replace(CatalogEntry before, CatalogEntry after) => onChanged([
    for (final e in entries)
      if (e.id == before.id) after else e,
  ]);

  void _remove(CatalogEntry entry) =>
      onChanged(entries.where((e) => e.id != entry.id).toList());

  /// Adds a row with a stable `custom_N` id (never `builtIn`).
  void _add(BuildContext context) => _edit(context, null);

  Future<void> _edit(BuildContext context, CatalogEntry? existing) async {
    final result = await showCatalogEntryDialog(context, entry: existing);
    if (result == null) return;
    if (existing == null) {
      final id = _nextCustomId();
      onChanged([
        ...entries,
        CatalogEntry(id: id, labelBn: result.bn, labelEn: result.en),
      ]);
      return;
    }
    _replace(
      existing,
      existing.copyWith(labelBn: result.bn, labelEn: result.en),
    );
  }

  /// `custom_1`, `custom_2`, … — the smallest number not in use.
  String _nextCustomId() {
    final used = entries.map((e) => e.id).toSet();
    var n = 1;
    while (used.contains('custom_$n')) {
      n++;
    }
    return 'custom_$n';
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.index,
    required this.showHandle,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    super.key,
  });

  final CatalogEntry entry;
  final int index;
  final bool showHandle;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  /// Null for a built-in row: built-ins are never deleted.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final label = entry.labelBn;
    final detail = entry.detail;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: showHandle
          ? ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.drag_handle_rounded, color: tokens.outline),
              ),
            )
          : null,
      title: Text(
        label,
        style: entry.active
            ? null
            : TextStyle(
                color: tokens.textDisabled,
                decoration: TextDecoration.lineThrough,
              ),
      ),
      subtitle: detail == null ? null : Text(detail),
      trailing: PopupMenuButton<String>(
        tooltip: l10n.catalogEditorActions,
        onSelected: (action) => switch (action) {
          'edit' => onEdit(),
          'toggle' => onToggleActive(),
          'delete' => onDelete?.call(),
          _ => null,
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
          PopupMenuItem(
            value: 'toggle',
            child: Text(
              entry.active
                  ? l10n.catalogEditorDeactivate
                  : l10n.catalogEditorActivate,
            ),
          ),
          if (onDelete != null)
            PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
        ],
      ),
    );
  }
}
