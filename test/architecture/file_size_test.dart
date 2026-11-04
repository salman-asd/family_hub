import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md "Split widget files over ~300 lines" (H11): no hand-written file in
/// `lib/` may exceed [_maxLines].
///
/// The allow-list names files that are long by nature (one table of tokens or
/// gallery entries) plus one documented debt.  Generated code is skipped.
void main() {
  const maxLines = 300;
  const allowed = <String>{
    'lib/app/gallery/gallery_sections.dart',
    'lib/app/theme/app_tokens.dart',
    'lib/app/theme/theme_builder.dart',
    // Debt: one repository implements the whole FamilyRepository port.  Split it
    // (members / invitations / settings) when Phase 2 adds no more to it.
    'lib/features/family/data/firestore_family_repository.dart',
    // Debt recorded in P3-30 (PROGRESS.md "P3-30"): Phase 3 files over the cap.
    // Line counts were taken BEFORE `dart format`, which reflows them, so split
    // only what is still over 300 after the first formatted run, then delete the
    // entry. Do not add new files here.
    'lib/features/chores/calendar/presentation/widgets/agenda_view.dart',
    'lib/features/chores/templates/presentation/widgets/recurrence_picker_sheet.dart',
    'lib/features/chores/templates/presentation/template_list_screen.dart',
    'lib/features/chores/templates/presentation/template_editor_controller.dart',
    'lib/features/chores/templates/presentation/template_editor_screen.dart',
    'lib/features/chores/occurrences/domain/chore_item.dart',
    'lib/features/chores/occurrences/domain/usecases/occurrence_action.dart',
    'lib/features/chores/occurrences/domain/chore_occurrence.dart',
    'lib/features/chores/settings/presentation/chore_settings_screen.dart',
    'lib/shared/widgets/catalog_editor.dart',
  };

  test('no lib file is longer than $maxLines lines', () {
    final tooLong = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.contains('/generated/') || allowed.contains(path)) continue;
      final lines = entity.readAsLinesSync().length;
      if (lines > maxLines) tooLong.add('$path ($lines lines)');
    }
    expect(
      tooLong,
      isEmpty,
      reason: 'Split these files:\n${tooLong.join('\n')}',
    );
  });
}
