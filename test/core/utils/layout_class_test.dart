import 'package:family_hub/core/utils/layout_class.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutClass.of', () {
    test('a phone in portrait is compact', () {
      expect(LayoutClass.of(360, 360), LayoutClass.compact);
      expect(LayoutClass.of(411, 411), LayoutClass.compact);
      expect(LayoutClass.of(599, 599), LayoutClass.compact);
    });

    test('a phone held sideways stays compact', () {
      // Wide enough for two panes, but the short side says "phone".
      expect(LayoutClass.of(800, 360), LayoutClass.compact);
      expect(LayoutClass.of(915, 427), LayoutClass.compact);
      expect(LayoutClass.of(1024, 500), LayoutClass.compact);
    });

    test('600 dp of width with a tablet short side is medium', () {
      expect(LayoutClass.of(600, 600), LayoutClass.medium);
      expect(LayoutClass.of(700, 700), LayoutClass.medium);
      expect(LayoutClass.of(839, 600), LayoutClass.medium);
    });

    test('840 dp of width is expanded', () {
      expect(LayoutClass.of(840, 600), LayoutClass.expanded);
      expect(LayoutClass.of(1024, 768), LayoutClass.expanded);
      expect(LayoutClass.of(1280, 800), LayoutClass.expanded);
    });

    test(
      'a portrait tablet is medium, the same tablet sideways is expanded',
      () {
        expect(LayoutClass.of(800, 1280), LayoutClass.medium);
        expect(LayoutClass.of(1280, 800), LayoutClass.expanded);
      },
    );

    test('only the expanded class shows two panes', () {
      expect(LayoutClass.compact.showsTwoPanes, isFalse);
      expect(LayoutClass.medium.showsTwoPanes, isFalse);
      expect(LayoutClass.expanded.showsTwoPanes, isTrue);
    });
  });
}
