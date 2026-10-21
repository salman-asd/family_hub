// Prints a Markdown coverage summary per top-level folder from
// coverage/lcov.info (H13).
//
// Usage: dart run tools/coverage_summary.dart [coverage/lcov.info]
//
// Lists every file under 70 percent in lib/core/ or lib/features/*/domain/ with
// its uncovered line count, so the owner knows where tests are missing.
import 'dart:io';

class _Cov {
  int found = 0;
  int hit = 0;
  double get percent => found == 0 ? 100 : hit * 100 / found;
}

String _group(String path) {
  final parts = path.replaceAll(r'\', '/').split('/');
  final i = parts.indexOf('lib');
  if (i < 0 || i + 1 >= parts.length) return 'other';
  final top = parts[i + 1];
  if (top == 'features' && i + 2 < parts.length) return 'features/${parts[i + 2]}';
  return top;
}

bool _mustBeCovered(String path) {
  final p = path.replaceAll(r'\', '/');
  return p.contains('/lib/core/') ||
      p.startsWith('lib/core/') ||
      RegExp(r'(^|/)lib/features/[^/]+/domain/').hasMatch(p);
}

void main(List<String> args) {
  final file = File(args.isEmpty ? 'coverage/lcov.info' : args.first);
  if (!file.existsSync()) {
    stderr.writeln('No coverage file at ${file.path}: run flutter test --coverage');
    exit(2);
  }
  final groups = <String, _Cov>{};
  final files = <String, _Cov>{};
  String? current;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      files[current] = _Cov();
    } else if (line.startsWith('LF:') && current != null) {
      files[current]!.found = int.parse(line.substring(3));
    } else if (line.startsWith('LH:') && current != null) {
      files[current]!.hit = int.parse(line.substring(3));
    }
  }
  for (final e in files.entries) {
    if (e.key.contains('/generated/') || e.key.contains(r'\generated\')) continue;
    final g = groups.putIfAbsent(_group(e.key), _Cov.new);
    g.found += e.value.found;
    g.hit += e.value.hit;
  }
  final names = groups.keys.toList()..sort();
  stdout
    ..writeln('| Folder | Lines | Covered | % |')
    ..writeln('| --- | ---: | ---: | ---: |');
  for (final n in names) {
    final c = groups[n]!;
    stdout.writeln('| $n | ${c.found} | ${c.hit} | ${c.percent.toStringAsFixed(1)} |');
  }
  stdout
    ..writeln()
    ..writeln('Files under 70% in core/ or features/*/domain/:')
    ..writeln();
  var any = false;
  final low = files.entries
      .where((e) => _mustBeCovered(e.key) && !e.key.contains('generated'))
      .where((e) => e.value.percent < 70)
      .toList()
    ..sort((a, b) => a.value.percent.compareTo(b.value.percent));
  for (final e in low) {
    any = true;
    stdout.writeln(
      '- `${e.key}`: ${e.value.percent.toStringAsFixed(1)}% '
      '(${e.value.found - e.value.hit} uncovered lines)',
    );
  }
  if (!any) stdout.writeln('- none');
}
