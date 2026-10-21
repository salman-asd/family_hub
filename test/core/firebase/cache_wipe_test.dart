import 'package:family_hub/core/firebase/cache_wipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('no flag: nothing is wiped', () async {
    var wiped = 0;
    final ran = await CacheWipe.wipeIfRequested(prefs, () async => wiped++);
    expect(ran, isFalse);
    expect(wiped, 0);
  });

  test('flag raised: wipes once and lowers the flag', () async {
    await CacheWipe.request(prefs);
    expect(CacheWipe.isRequested(prefs), isTrue);
    var wiped = 0;
    expect(await CacheWipe.wipeIfRequested(prefs, () async => wiped++), isTrue);
    expect(wiped, 1);
    expect(CacheWipe.isRequested(prefs), isFalse);
    expect(await CacheWipe.wipeIfRequested(prefs, () async => wiped++), isFalse);
    expect(wiped, 1);
  });

  test('a failed wipe keeps the flag for the next start', () async {
    await CacheWipe.request(prefs);
    await expectLater(
      CacheWipe.wipeIfRequested(prefs, () async => throw StateError('busy')),
      throwsStateError,
    );
    expect(CacheWipe.isRequested(prefs), isTrue);
  });
}
