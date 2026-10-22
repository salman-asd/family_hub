import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md rule 19 (H7): the UI never tests a role.  Screens ask
/// `ref.can(Permission.x)` / `canProvider` / `PermissionGate`, so the matrix in
/// `PermissionPolicy` stays the only place that knows what a role may do.
void main() {
  final forbidden = RegExp(
    r'\.isAdmin\b|\.isModerator\b|canManageMembers|'
    r'MemberRole\.(admin|moderator)\b|Role\.(admin|moderator)\b',
  );

  test('the detector recognises each banned form', () {
    for (final bad in [
      'if (membership.isAdmin) {}',
      'me?.isModerator',
      'membership?.canManageMembers',
      'role == MemberRole.admin',
      'role == MemberRole.moderator',
      'role == Role.admin',
      'Role.moderator',
    ]) {
      expect(forbidden.hasMatch(bad), isTrue, reason: bad);
    }
    for (final fine in [
      'ref.can(Permission.inviteMembers)',
      'm.isActiveAdmin',
      'MemberRole.member',
      'l10n.roleLabel(m.role)',
    ]) {
      expect(forbidden.hasMatch(fine), isFalse, reason: fine);
    }
  });

  test('no role checks in lib/features/*/presentation or lib/shared', () {
    final files = <File>[];
    final features = Directory('lib/features');
    if (features.existsSync()) {
      files.addAll(
        features
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) => f.path.replaceAll(r'\', '/').contains('/presentation/'),
            ),
      );
    }
    final shared = Directory('lib/shared');
    if (shared.existsSync()) {
      files.addAll(shared.listSync(recursive: true).whereType<File>());
    }

    final found = <String>[];
    for (final file in files.where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (forbidden.hasMatch(line)) {
          found.add(
            '${file.path.replaceAll(r'\', '/')}:${i + 1}: ${line.trim()}',
          );
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
