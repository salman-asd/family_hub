import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/core/utils/unit_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseUnit', () {
    test('accepts the Bangla names', () {
      expect(parseUnit('কেজি'), Unit.kg);
      expect(parseUnit('গ্রাম'), Unit.g);
      expect(parseUnit('লিটার'), Unit.litre);
      expect(parseUnit('টা'), Unit.piece);
      expect(parseUnit('টি'), Unit.piece);
      expect(parseUnit('পিস'), Unit.piece);
      expect(parseUnit('ডজন'), Unit.dozen);
      expect(parseUnit('প্যাকেট'), Unit.packet);
      expect(parseUnit('সিলিন্ডার'), Unit.cylinder);
    });

    test('accepts the English names case-insensitively', () {
      expect(parseUnit('kg'), Unit.kg);
      expect(parseUnit('KILO'), Unit.kg);
      expect(parseUnit('Gm'), Unit.g);
      expect(parseUnit('gram'), Unit.g);
      expect(parseUnit('L'), Unit.litre);
      expect(parseUnit('liter'), Unit.litre);
      expect(parseUnit('Piece'), Unit.piece);
      expect(parseUnit('pcs'), Unit.piece);
      expect(parseUnit('DOZEN'), Unit.dozen);
      expect(parseUnit('packet'), Unit.packet);
      expect(parseUnit('pack'), Unit.packet);
      expect(parseUnit('Cylinder'), Unit.cylinder);
    });

    test('trims surrounding whitespace', () {
      expect(parseUnit('  kg  '), Unit.kg);
      expect(parseUnit('\tডজন\n'), Unit.dozen);
    });

    test('unknown, empty and partial names return null', () {
      expect(parseUnit(''), isNull);
      expect(parseUnit('   '), isNull);
      expect(parseUnit('kilogram'), isNull);
      expect(parseUnit('bucket'), isNull);
      expect(parseUnit('কেজ'), isNull);
    });
  });

  group('UnitInfo', () {
    test('weight units', () {
      expect(Unit.kg.isWeight, isTrue);
      expect(Unit.g.isWeight, isTrue);
      expect(Unit.litre.isWeight, isFalse);
      expect(Unit.piece.isWeight, isFalse);
    });

    test('volume unit', () {
      expect(Unit.litre.isVolume, isTrue);
      expect(Unit.kg.isVolume, isFalse);
      expect(Unit.cylinder.isVolume, isFalse);
    });

    test('count units', () {
      expect(Unit.piece.isCount, isTrue);
      expect(Unit.dozen.isCount, isTrue);
      expect(Unit.packet.isCount, isTrue);
      expect(Unit.cylinder.isCount, isTrue);
      expect(Unit.kg.isCount, isFalse);
      expect(Unit.litre.isCount, isFalse);
    });

    test('every unit belongs to exactly one kind', () {
      for (final unit in Unit.values) {
        final kinds = [unit.isWeight, unit.isVolume, unit.isCount];
        expect(
          kinds.where((kind) => kind).length,
          1,
          reason: '${unit.name} must have exactly one kind',
        );
      }
    });
  });
}
