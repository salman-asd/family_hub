import 'package:family_hub/core/utils/value_equality.dart';
import 'package:flutter_test/flutter_test.dart';

/// Maps and lists are compared by content, so a value built twice is equal.
void main() {
  group('sameValue', () {
    test('equal but distinct maps and lists are the same value', () {
      expect(
        sameValue(
          <String, Object?>{'at': 1, 'by': 'cara'},
          <String, Object?>{'at': 1, 'by': 'cara'},
        ),
        isTrue,
      );
      expect(
        sameValue(
          <Object?>[
            1,
            <String, Object?>{'a': 2},
          ],
          <Object?>[
            1,
            <String, Object?>{'a': 2},
          ],
        ),
        isTrue,
      );
    });

    test('the order of map entries does not matter, that of a list does', () {
      expect(
        sameValue(
          <String, Object?>{'a': 1, 'b': 2},
          <String, Object?>{'b': 2, 'a': 1},
        ),
        isTrue,
      );
      expect(sameValue(<Object?>[1, 2], <Object?>[2, 1]), isFalse);
    });

    test('a missing or different entry is not the same value', () {
      expect(
        sameValue(<String, Object?>{'a': 1}, <String, Object?>{'a': 2}),
        isFalse,
      );
      expect(
        sameValue(<String, Object?>{'a': 1, 'b': 1}, <String, Object?>{'a': 1}),
        isFalse,
      );
      expect(sameValue(<String, Object?>{'a': 1}, 'a'), isFalse);
    });

    test('scalars fall back to ==', () {
      expect(sameValue(1, 1), isTrue);
      expect(sameValue(null, null), isTrue);
      expect(sameValue(null, 0), isFalse);
    });
  });

  group('hashValue', () {
    test('equal values hash equal, whatever their build', () {
      final a = <String, Object?>{
        'at': 7,
        'by': 'cara',
        'steps': <Object?>['x', 'y'],
      };
      final b = <String, Object?>{
        'by': 'cara',
        'steps': <Object?>['x', 'y'],
        'at': 7,
      };
      expect(sameValue(a, b), isTrue);
      expect(hashValue(a), hashValue(b));
      expect(hashValue(<Object?>[a]), hashValue(<Object?>[b]));
    });

    test('a scalar hashes like its own hashCode', () {
      expect(hashValue(3), 3.hashCode);
      expect(hashValue(null), null.hashCode);
    });
  });
}
