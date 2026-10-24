import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item_search.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(
  String id,
  String nameBn, {
  String? nameEn,
  List<String> aliases = const <String>[],
  String categoryId = 'veg',
  int useCount = 0,
  bool builtIn = true,
  bool active = true,
}) => Item(
  id: id,
  nameBn: nameBn,
  nameEn: nameEn,
  categoryId: categoryId,
  defaultUnit: Unit.kg,
  aliases: aliases,
  useCount: useCount,
  builtIn: builtIn,
  active: active,
);

List<String> _ids(Iterable<Item> items) => <String>[
  for (final item in items) item.id,
];

void main() {
  late Item alu;
  late Item alurDal;
  late Item begun;
  late Item avocado;
  late Item chips;
  late Item pore;
  late ItemSearch search;

  setUp(() {
    alu = _item(
      'i-alu',
      'আলু',
      nameEn: 'Potato',
      aliases: const <String>['alu', 'potato'],
      useCount: 10,
    );
    alurDal = _item(
      'i-dal',
      'আলুর ডাল',
      nameEn: 'Lentil',
      aliases: const <String>['dal'],
      useCount: 2,
    );
    begun = _item(
      'i-begun',
      'বেগুন',
      nameEn: 'Eggplant',
      aliases: const <String>['begun', 'brinjal'],
    );
    avocado = _item(
      'i-avo',
      'অ্যাভোকাডো',
      nameEn: 'Avocado',
      aliases: const <String>['avocado'],
      categoryId: 'fruit',
      useCount: 50,
      builtIn: false,
    );
    chips = _item(
      'i-chips',
      'চিপস',
      nameEn: 'Potato chips',
      aliases: const <String>['chips'],
      useCount: 30,
      builtIn: false,
    );
    pore = _item(
      'i-pore',
      'পড়া',
      aliases: const <String>['pore'],
      useCount: 1,
    );
    search = ItemSearch(<Item>[
      alu,
      alurDal,
      begun,
      avocado,
      chips,
      _item(
        'i-chips-off',
        'আলু চিপস',
        nameEn: 'Potato chips',
        aliases: const <String>['chips'],
        useCount: 99,
        active: false,
      ),
      pore,
    ]);
  });

  test('finds আলু through its Latin alias', () {
    expect(_ids(search.search('alu')), <String>['i-alu']);
  });

  test('a Bangla prefix puts আলু first', () {
    expect(_ids(search.search('আ')).first, 'i-alu');
  });

  test('finds an English name', () {
    expect(_ids(search.search('potato')), <String>['i-alu', 'i-chips']);
  });

  test('an exact match beats a prefix with a higher use count', () {
    // `i-chips` has useCount 30, but `potato` is an exact name for `i-alu`.
    expect(_ids(search.search('potato')).first, 'i-alu');
  });

  test('a frequent custom item beats a predefined item', () {
    // Both match tier 1 for `a`; the custom item is used more often.
    final result = _ids(search.search('a'));
    expect(result.take(2), <String>['i-avo', 'i-alu']);
  });

  test('inactive items are hidden', () {
    final result = search.search('chips');
    expect(_ids(result), <String>['i-chips']);
  });

  test('an empty query lists frequent items, then built-ins in seed order', () {
    expect(_ids(search.search('')), <String>[
      'i-avo',
      'i-chips',
      'i-alu',
      'i-dal',
      'i-pore',
      'i-begun',
    ]);
  });

  test('the limit caps the result', () {
    expect(_ids(search.search('', limit: 2)), <String>['i-avo', 'i-chips']);
    expect(search.search('', limit: 0), isEmpty);
  });

  test('a nukta-variant spelling matches', () {
    expect(_ids(search.search('পড\u09BCা')), <String>['i-pore']);
  });

  test('a word prefix and a contains match both work', () {
    expect(_ids(search.search('ডাল')), <String>['i-dal']);
    expect(_ids(search.search('গুন')), <String>['i-begun']);
  });

  test('the category filter is applied', () {
    expect(_ids(search.search('', categoryId: 'fruit')), <String>['i-avo']);
    expect(search.search('potato', categoryId: 'fruit'), isEmpty);
  });

  test('a missing query returns nothing', () {
    expect(search.search('কিছুই নেই'), isEmpty);
  });
}
