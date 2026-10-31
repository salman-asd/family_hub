import 'dart:io';

import 'package:family_hub/features/chores/settings/domain/default_chore_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-P3-4 / CLAUDE.md rule 34 (P-01, Wave R6): no literal option list in a
/// widget.
///
/// Chore groups, due-time presets and absence reasons are DATA that lives in
/// `settings/chores`; a screen renders the list it is given.  This test reads
/// the seed ids from [seedOptionIds] (the only place allowed to spell them) and
/// fails if a presentation file under `lib/features/chores/` or
/// `lib/shared/widgets/` contains one as a quoted string.
///
/// Exempt:
/// - `chore_icons.dart`: it maps an `iconKey` to an icon, which is a closed set
///   of drawable icons, not an option list (U-12).
/// - starter-pack data files (`starter_pack*`), which seed templates.
void main() {
  const exemptFiles = <String>{'chore_icons.dart'};

  bool inScope(String path) {
    final inChores =
        path.startsWith('lib/features/chores/') &&
        path.contains('/presentation/');
    final inShared = path.startsWith('lib/shared/widgets/');
    if (!inChores && !inShared) return false;
    final name = path.split('/').last;
    return !exemptFiles.contains(name) && !name.startsWith('starter_pack');
  }

  /// The seed ids that appear in [source] as a quoted literal.
  Set<String> literalsIn(String source) {
    final hits = <String>{};
    for (final raw in source.split('\n')) {
      final line = raw.trimLeft();
      if (line.startsWith('//')) continue;
      for (final id in seedOptionIds) {
        if (line.contains("'$id'") || line.contains('"$id"')) hits.add(id);
      }
    }
    return hits;
  }

  test('the detector sees a quoted seed id and ignores comments', () {
    expect(literalsIn("final g = ['kitchen', 'x'];"), <String>{'kitchen'});
    expect(literalsIn('final p = "morning";'), <String>{'morning'});
    expect(literalsIn("// 'kitchen' is only a comment"), isEmpty);
    expect(literalsIn("final s = 'kitchenette';"), isEmpty);
  });

  test('the seed set is the Appendix A.3 set (minus the generic "other")', () {
    expect(seedOptionIds, contains('kitchen'));
    expect(seedOptionIds, contains('sick'));
    expect(seedOptionIds, contains('bedtime'));
    expect(seedOptionIds, isNot(contains('other')));
  });

  test('no presentation file spells a seed id', () {
    final offenders = <String>[];
    var scanned = 0;
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!inScope(path)) continue;
      scanned++;
      final hits = literalsIn(entity.readAsStringSync());
      if (hits.isNotEmpty) offenders.add('$path: ${hits.join(', ')}');
    }
    expect(scanned, greaterThan(10), reason: 'the scan found no files');
    expect(
      offenders,
      isEmpty,
      reason:
          'Render the list from a provider instead (D-P3-4):\n'
          '${offenders.join('\n')}',
    );
  });
}
