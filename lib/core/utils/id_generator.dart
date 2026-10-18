import 'dart:math';

/// Produces a new unique document id.  Injected so tests are deterministic.
typedef IdGenerator = String Function();

const String _idAlphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// 20-character random id (url/Firestore safe).
String randomId([Random? random]) {
  final r = random ?? Random.secure();
  return String.fromCharCodes(
    List<int>.generate(
      20,
      (_) => _idAlphabet.codeUnitAt(r.nextInt(_idAlphabet.length)),
    ),
  );
}
