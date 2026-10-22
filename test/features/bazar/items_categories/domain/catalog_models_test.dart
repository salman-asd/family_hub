import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category', () {
    const category = Category(
      id: 'cat_food',
      nameBn: 'খাবার',
      nameEn: 'Food',
      colorIndex: 3,
      sortOrder: 1,
      builtIn: true,
      seedKey: 'food',
    );

    test('displayName falls back to the other language', () {
      expect(category.displayName(bangla: true), 'খাবার');
      expect(category.displayName(bangla: false), 'Food');
      const banglaOnly = Category(
        id: 'cat_x',
        nameBn: 'শুধু বাংলা',
        colorIndex: 0,
        sortOrder: 0,
      );
      expect(banglaOnly.displayName(bangla: false), 'শুধু বাংলা');
      const englishOnly = Category(
        id: 'cat_y',
        nameBn: '',
        nameEn: 'English only',
        colorIndex: 0,
        sortOrder: 0,
      );
      expect(englishOnly.displayName(bangla: true), 'English only');
    });

    test('copyWith keeps fields and equality compares every field', () {
      final renamed = category.copyWith(nameBn: 'খাদ্য');
      expect(renamed.nameBn, 'খাদ্য');
      expect(renamed.seedKey, 'food');
      expect(renamed, isNot(category));
      expect(renamed, category.copyWith(nameBn: 'খাদ্য'));
      expect(renamed.hashCode, category.copyWith(nameBn: 'খাদ্য').hashCode);
    });
  });

  group('Item', () {
    final item = Item(
      id: 'item_rice',
      nameBn: 'চাল',
      nameEn: 'Rice',
      categoryId: 'cat_food',
      defaultUnit: Unit.kg,
      aliases: const <String>['chal', 'rice'],
      useCount: 4,
      lastPrice: const Money.paisa(12000),
      lastUnitPrice: const Money.paisa(6000),
      lastUsedAt: DateTime.utc(2026, 10, 1),
      builtIn: true,
      seedKey: 'rice',
    );

    test('displayName falls back to the other language', () {
      expect(item.displayName(bangla: true), 'চাল');
      expect(item.displayName(bangla: false), 'Rice');
      expect(item.copyWith(nameEn: '').displayName(bangla: false), 'চাল');
    });

    test('equality compares aliases by content', () {
      expect(item, item.copyWith(aliases: const <String>['chal', 'rice']));
      expect(
        item.hashCode,
        item.copyWith(aliases: const <String>['chal', 'rice']).hashCode,
      );
      expect(item, isNot(item.copyWith(aliases: const <String>['chal'])));
      expect(item, isNot(item.copyWith(useCount: 5)));
      expect(item, isNot(item.copyWith(lastPrice: const Money.paisa(1))));
    });

    test('copyWith keeps the id and untouched fields', () {
      final updated = item.copyWith(nameBn: 'মিনিকেট চাল', useCount: 5);
      expect(updated.id, item.id);
      expect(updated.nameBn, 'মিনিকেট চাল');
      expect(updated.useCount, 5);
      expect(updated.lastPrice, const Money.paisa(12000));
      expect(updated.defaultUnit, Unit.kg);
    });
  });
}
