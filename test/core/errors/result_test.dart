import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('map transforms success and passes failure through', () {
      const Result<int> ok = Success<int>(2);
      const Result<int> bad = Failure<int>(PermissionDenied());
      expect(ok.map((v) => v * 3).valueOrNull, 6);
      expect(bad.map((v) => v * 3).failureOrNull, const PermissionDenied());
    });

    test('flatMap returns the first failure', () {
      const Result<int> ok = Success<int>(2);
      final chained = ok.flatMap<int>(
        (v) => const Failure<int>(Conflict(code: 'locked')),
      );
      expect(chained.failureOrNull, const Conflict(code: 'locked'));
      expect(
        ok.flatMap<String>((v) => Success<String>('$v')).valueOrNull,
        '2',
      );
    });

    test('when folds both cases', () {
      const Result<int> ok = Success<int>(1);
      const Result<int> bad = Failure<int>(Network());
      expect(ok.when(success: (v) => 'v$v', failure: (_) => 'f'), 'v1');
      expect(bad.when(success: (v) => 'v$v', failure: (_) => 'f'), 'f');
    });

    test('flags and equality', () {
      const Result<int> ok = Success<int>(1);
      expect(ok.isSuccess, isTrue);
      expect(ok.isFailure, isFalse);
      expect(const Success<int>(1), const Success<int>(1));
      expect(
        const Failure<int>(Validation('a', 'b')),
        const Failure<int>(Validation('a', 'b')),
      );
    });

    test('AppFailure is exhaustively switchable', () {
      String name(AppFailure f) => switch (f) {
            PermissionDenied() => 'permission',
            NotFound() => 'notFound',
            Validation() => 'validation',
            Conflict() => 'conflict',
            Network() => 'network',
            Unknown() => 'unknown',
          };
      expect(name(const Validation('x', 'y')), 'validation');
      expect(name(const Unknown('boom')), 'unknown');
    });
  });
}
