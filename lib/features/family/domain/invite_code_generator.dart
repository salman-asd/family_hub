import 'dart:math';

import 'package:family_hub/features/family/domain/invitation.dart';

/// Generates invitation codes from an unambiguous alphabet (no 0/O, 1/I/L).
class InviteCodeGenerator {
  InviteCodeGenerator([Random? random]) : _random = random ?? Random.secure();

  static const String alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  final Random _random;

  String next() => String.fromCharCodes(
    List<int>.generate(
      Invitation.codeLength,
      (_) => alphabet.codeUnitAt(_random.nextInt(alphabet.length)),
    ),
  );

  /// Upper-cases and strips spaces/dashes from user input.
  static String normalize(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  /// True when [code] has the right length and only alphabet characters.
  static bool isWellFormed(String code) =>
      code.length == Invitation.codeLength &&
      code.split('').every(alphabet.contains);
}
