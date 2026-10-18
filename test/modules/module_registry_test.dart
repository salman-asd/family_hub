import 'package:family_hub/features/bazar/bazar_module.dart';
import 'package:family_hub/features/chores/chores_module.dart';
import 'package:family_hub/modules/module_flags.dart';
import 'package:family_hub/modules/module_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModuleRegistry', () {
    test('standard registry lists Chores then Bazar with unique ids', () {
      final registry = ModuleRegistry.standard();
      expect(registry.modules.map((m) => m.id), ['chores', 'bazar']);
    });

    test('every module has names, a base path and at least one route', () {
      for (final m in ModuleRegistry.standard().modules) {
        expect(m.nameBn, isNotEmpty, reason: m.id);
        expect(m.nameEn, isNotEmpty, reason: m.id);
        expect(m.basePath, startsWith('/'), reason: m.id);
        expect(m.routes, isNotEmpty, reason: m.id);
      }
    });

    test('byId finds a module and returns null for an unknown id', () {
      final registry = ModuleRegistry.standard();
      expect(registry.byId('bazar'), isA<BazarModule>());
      expect(registry.byId('events'), isNull);
    });

    test('duplicate ids are rejected', () {
      expect(
        () => ModuleRegistry(const [ChoresModule(), ChoresModule()]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('enabled / disabled follow the flags and keep registry order', () {
      final registry = ModuleRegistry.standard();
      const off = ModuleFlags({'chores': false});
      expect(registry.enabled(ModuleFlags.allOn).map((m) => m.id),
          ['chores', 'bazar']);
      expect(registry.enabled(off).map((m) => m.id), ['bazar']);
      expect(registry.disabled(off).map((m) => m.id), ['chores']);
    });
  });

  group('ModuleFlags', () {
    test('default is everything on, including modules it has never heard of',
        () {
      expect(ModuleFlags.allOn.isEnabled('chores'), isTrue);
      expect(ModuleFlags.allOn.isEnabled('events'), isTrue);
    });

    test('withFlag switches one module and leaves the others', () {
      final flags = ModuleFlags.allOn.withFlag('bazar', enabled: false);
      expect(flags.isEnabled('bazar'), isFalse);
      expect(flags.isEnabled('chores'), isTrue);
    });

    test('equality ignores explicit-true entries', () {
      expect(const ModuleFlags({'chores': true}), ModuleFlags.allOn);
      expect(
        const ModuleFlags({'chores': true}).hashCode,
        ModuleFlags.allOn.hashCode,
      );
      expect(
        const ModuleFlags({'chores': false}) == ModuleFlags.allOn,
        isFalse,
      );
    });
  });
}
