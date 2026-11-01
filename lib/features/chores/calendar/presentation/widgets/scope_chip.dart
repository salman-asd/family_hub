import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:flutter/material.dart';

/// "My chores / Whole family": one tap flips it (B.4). The icon AND the label
/// change, never the colour alone.
class ScopeChip extends StatelessWidget {
  const ScopeChip({required this.scope, required this.onToggle, super.key});

  final CalendarScope scope;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mine = scope == CalendarScope.mine;
    return ActionChip(
      key: const Key('calendar_scope_chip'),
      avatar: Icon(
        mine ? Icons.person_rounded : Icons.groups_rounded,
        size: 18,
      ),
      label: Text(
        mine ? l10n.choresCalendarScopeMine : l10n.choresCalendarScopeAll,
      ),
      onPressed: onToggle,
    );
  }
}
