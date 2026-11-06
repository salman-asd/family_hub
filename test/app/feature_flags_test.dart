import 'package:family_hub/app/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('push backend is unavailable while the family stays on Spark', () {
    expect(FeatureFlags.pushBackend, isFalse);
  });

  test('Ask AI is off (road map section 11: dormant until its own step)', () {
    expect(FeatureFlags.askAi, isFalse);
  });
}
