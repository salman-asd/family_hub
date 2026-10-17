import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fails when a `Text(` widget is constructed from a hard-coded string literal.
///
/// The roadmap (Step 5) asks for "a script or test that greps lib/ for
/// hard-coded string literals inside Text( widgets".  Everything user-visible
/// must come from `AppLocalizations` via `context.l10n`, so a literal such as
/// `Text('Save')` is a bug.  Legitimate exceptions:
///
///   * `Text(variable)` / `Text(l10n.someKey)` — not a literal.
///   * Developer-only surfaces (the `/dev/tokens` screen) whose labels are
///     token identifiers, not copy.  Allow-listed via [_allowedFiles].
///   * String literals with an explicit `// i18n-exempt` comment on the same
///     line (e.g. a non-translatable debug label).
///
/// The scan is regex-based on purpose: it must run in plain `flutter test`
/// without a build step, and it only needs to catch the common mistake.
void main() {
  test('detector recognises literal Text( widgets', () {
    // Guard against a vacuous pass: the regex must match known-bad lines.
    expect(_literalText.hasMatch("Text('Save')"), isTrue);
    expect(_literalText.hasMatch('Text("Save")'), isTrue);
    expect(_constLiteralText.hasMatch("Text(const 'Save')"), isTrue);
    expect(_literalText.hasMatch('Text(l10n.actionSave)'), isFalse);
    expect(_literalText.hasMatch('Text(someVariable)'), isFalse);
  });

  test('no hard-coded string literals inside Text( widgets in lib/', () {
    final offenders = <String>[];

    for (final file in _dartFiles(Directory('lib'))) {
      final path = file.path.replaceAll(r'\', '/');
      if (_allowedFiles.any(path.endsWith)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('// i18n-exempt')) continue;

        // Text('...')  or  Text("...")  — a literal first argument.
        final match = _literalText.firstMatch(line);
        if (match != null) {
          offenders.add('$path:${i + 1}: ${line.trim()}');
        }

        // Also catch const Text('...').
        final constMatch = _constLiteralText.firstMatch(line);
        if (constMatch != null) {
          offenders.add('$path:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Hard-coded strings in Text( widgets found. Move them to the ARB '
          'files and read them with context.l10n:\n${offenders.join('\n')}',
    );
  });
}

/// `Text('literal'` or `Text("literal"` (optionally with named args after).
final RegExp _literalText = RegExp(r"""\bText\(\s*['"]""");

/// `const Text('literal'` / `Text.rich('literal'`-style const literals.
final RegExp _constLiteralText = RegExp(r"""\bText\(\s*const\s+['"]""");

/// Files allowed to contain literal labels because they render developer token
/// names or non-translatable identifiers rather than user copy.
const List<String> _allowedFiles = [
  // Dev-only token swatch screen: labels are token identifiers like 'surface'.
  'lib/app/theme/dev_tokens_screen.dart',
];

/// Recursively collects `.dart` files under [dir], skipping generated code.
List<File> _dartFiles(Directory dir) {
  final result = <File>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final path = entity.path.replaceAll(r'\', '/');
      // Generated localizations contain literals by design.
      if (path.contains('/generated/')) continue;
      result.add(entity);
    }
  }
  return result;
}
