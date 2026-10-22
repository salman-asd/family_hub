import 'package:family_hub/core/utils/quantity.dart';

/// One category in the starter catalog (Appendix A of the Phase 2 roadmap).
///
/// Pure `const` data: [id] is deterministic (`cat_<key>`) so a retried family
/// create cannot duplicate the seed.  [colorIndex] indexes the theme's
/// `placeholderPalette`; the document never stores a hex colour.
final class SeedCategory {
  const SeedCategory(
    this.key,
    this.bn,
    this.en,
    this.colorIndex,
    this.emoji,
    this.order,
  );

  final String key;
  final String bn;
  final String en;
  final int colorIndex;
  final String emoji;
  final int order;

  String get id => 'cat_$key';
}

/// One item in the starter catalog (Appendix A of the Phase 2 roadmap).
///
/// [categoryKey] is a [SeedCategory.key]; [aliases] are extra search words.
/// The item is always found by its Bangla and English names as well.
final class SeedItem {
  const SeedItem(
    this.key,
    this.bn,
    this.en,
    this.categoryKey,
    this.unit, [
    this.aliases = const <String>[],
  ]);

  final String key;
  final String bn;
  final String en;
  final String categoryKey;
  final Unit unit;
  final List<String> aliases;

  String get id => 'item_$key';
  String get categoryId => 'cat_$categoryKey';
}

/// The 11 starter categories, in display order (Appendix A).
const List<SeedCategory> defaultCatalogCategories = <SeedCategory>[
  SeedCategory('vegetables', 'সবজি', 'Vegetables', 0, '🫑', 0),
  SeedCategory('fish', 'মাছ', 'Fish', 1, '🐟', 1),
  SeedCategory('fruits', 'ফল', 'Fruits', 2, '🍎', 2),
  SeedCategory('beef', 'গরুর মাংস', 'Beef', 3, '🐄', 3),
  SeedCategory('chicken', 'মুরগির মাংস', 'Chicken', 4, '🐔', 4),
  SeedCategory('eggs', 'ডিম', 'Eggs', 5, '🥚', 5),
  SeedCategory('dry_groceries', 'শুকনা বাজার', 'Dry groceries', 6, '🛒', 6),
  SeedCategory('gas', 'গ্যাস', 'Gas', 7, '⛽', 7),
  SeedCategory('medicine', 'ঔষধ', 'Medicine', 8, '💊', 8),
  SeedCategory('other', 'অন্যান্য', 'Other', 9, '🅾️', 9),
  SeedCategory('fixed_bills', 'স্থায়ী বিল', 'Fixed bills', 10, '🏠', 10),
];

/// The 54 starter items, in Appendix A order.
const List<SeedItem> defaultCatalogItems = <SeedItem>[
  // Vegetables (15).
  SeedItem('potato', 'আলু', 'Potato', 'vegetables', Unit.kg, ['alu', 'aloo']),
  SeedItem('onion', 'পেঁয়াজ', 'Onion', 'vegetables', Unit.kg, [
    'peyaj',
    'piyaj',
    'পিয়াজ',
    'পেয়াজ',
  ]),
  SeedItem('garlic', 'রসুন', 'Garlic', 'vegetables', Unit.kg, [
    'roshun',
    'rosun',
  ]),
  SeedItem('ginger', 'আদা', 'Ginger', 'vegetables', Unit.kg, ['ada']),
  SeedItem('tomato', 'টমেটো', 'Tomato', 'vegetables', Unit.kg, ['tometo']),
  SeedItem('eggplant', 'বেগুন', 'Eggplant', 'vegetables', Unit.kg, [
    'begun',
    'brinjal',
  ]),
  SeedItem('cauliflower', 'ফুলকপি', 'Cauliflower', 'vegetables', Unit.piece, [
    'fulkopi',
  ]),
  SeedItem('cabbage', 'বাঁধাকপি', 'Cabbage', 'vegetables', Unit.piece, [
    'badhakopi',
    'bandhakopi',
  ]),
  SeedItem('cucumber', 'শসা', 'Cucumber', 'vegetables', Unit.kg, [
    'shosha',
    'sosha',
  ]),
  SeedItem('green_chili', 'কাঁচা মরিচ', 'Green chili', 'vegetables', Unit.kg, [
    'morich',
    'kacha morich',
    'chili',
  ]),
  SeedItem('bottle_gourd', 'লাউ', 'Bottle gourd', 'vegetables', Unit.piece, [
    'lau',
  ]),
  SeedItem('pointed_gourd', 'পটল', 'Pointed gourd', 'vegetables', Unit.kg, [
    'potol',
  ]),
  SeedItem('spinach', 'পালং শাক', 'Spinach', 'vegetables', Unit.kg, [
    'palong',
    'shak',
  ]),
  SeedItem('lemon', 'লেবু', 'Lemon', 'vegetables', Unit.piece, ['lebu']),
  SeedItem('carrot', 'গাজর', 'Carrot', 'vegetables', Unit.kg, ['gajor']),

  // Fish (6).
  SeedItem('rui', 'রুই', 'Rui', 'fish', Unit.kg),
  SeedItem('katla', 'কাতলা', 'Katla', 'fish', Unit.kg),
  SeedItem('hilsa', 'ইলিশ', 'Hilsa', 'fish', Unit.kg, ['ilish']),
  SeedItem('tilapia', 'তেলাপিয়া', 'Tilapia', 'fish', Unit.kg),
  SeedItem('pangas', 'পাঙ্গাস', 'Pangas', 'fish', Unit.kg),
  SeedItem('dried_fish', 'শুটকি', 'Dried fish', 'fish', Unit.kg, ['shutki']),

  // Fruits (5).
  SeedItem('banana', 'কলা', 'Banana', 'fruits', Unit.dozen, ['kola']),
  SeedItem('apple', 'আপেল', 'Apple', 'fruits', Unit.kg),
  SeedItem('pineapple', 'আনারস', 'Pineapple', 'fruits', Unit.piece, [
    'anarosh',
  ]),
  SeedItem('guava', 'পেয়ারা', 'Guava', 'fruits', Unit.kg, ['peyara']),
  SeedItem('orange', 'কমলা', 'Orange', 'fruits', Unit.kg, ['komola']),

  // Beef, chicken, eggs (3).
  SeedItem('beef', 'গরুর মাংস', 'Beef', 'beef', Unit.kg, ['goru', 'mangsho']),
  SeedItem('chicken', 'মুরগি', 'Chicken', 'chicken', Unit.kg, [
    'murgi',
    'broiler',
  ]),
  SeedItem('egg', 'ডিম', 'Eggs', 'eggs', Unit.dozen, ['dim', 'egg']),

  // Dry groceries (17).
  SeedItem('rice', 'চাল', 'Rice', 'dry_groceries', Unit.kg, ['chal']),
  SeedItem('polao_rice', 'পোলাও চাল', 'Polao rice', 'dry_groceries', Unit.kg),
  SeedItem('lentil', 'মসুর ডাল', 'Red lentil', 'dry_groceries', Unit.kg, [
    'dal',
    'masoor',
  ]),
  SeedItem(
    'soybean_oil',
    'সয়াবিন তেল',
    'Soybean oil',
    'dry_groceries',
    Unit.litre,
    ['tel', 'oil'],
  ),
  SeedItem(
    'mustard_oil',
    'সরিষার তেল',
    'Mustard oil',
    'dry_groceries',
    Unit.litre,
  ),
  SeedItem('flour', 'আটা', 'Flour', 'dry_groceries', Unit.kg, ['ata']),
  SeedItem('sugar', 'চিনি', 'Sugar', 'dry_groceries', Unit.kg, ['chini']),
  SeedItem('salt', 'লবণ', 'Salt', 'dry_groceries', Unit.kg, ['lobon', 'লবন']),
  SeedItem(
    'chili_powder',
    'মরিচের গুঁড়া',
    'Chili powder',
    'dry_groceries',
    Unit.kg,
    ['morich gura'],
  ),
  SeedItem(
    'turmeric_powder',
    'হলুদের গুঁড়া',
    'Turmeric powder',
    'dry_groceries',
    Unit.kg,
    ['holud'],
  ),
  SeedItem(
    'coriander_powder',
    'ধনিয়ার গুঁড়া',
    'Coriander powder',
    'dry_groceries',
    Unit.kg,
    ['dhonia'],
  ),
  SeedItem('cumin', 'জিরা', 'Cumin', 'dry_groceries', Unit.kg, ['jira']),
  SeedItem(
    'garam_masala',
    'গরম মশলা',
    'Garam masala',
    'dry_groceries',
    Unit.packet,
    ['moshla'],
  ),
  SeedItem('tea', 'চা পাতা', 'Tea leaves', 'dry_groceries', Unit.kg, ['cha']),
  SeedItem('milk', 'দুধ', 'Milk', 'dry_groceries', Unit.litre, ['dudh']),
  SeedItem('puffed_rice', 'মুড়ি', 'Puffed rice', 'dry_groceries', Unit.kg, [
    'muri',
  ]),
  SeedItem('noodles', 'নুডুলস', 'Noodles', 'dry_groceries', Unit.packet),

  // Gas, medicine, fixed bills, other (8).
  SeedItem(
    'gas_cylinder',
    'গ্যাস সিলিন্ডার',
    'Gas cylinder',
    'gas',
    Unit.cylinder,
    ['gas'],
  ),
  SeedItem('medicine', 'ঔষধ', 'Medicine', 'medicine', Unit.piece, [
    'oshudh',
    'medicine',
  ]),
  SeedItem('flat_rent', 'ফ্লাট ভাড়া', 'Flat rent', 'fixed_bills', Unit.piece, [
    'rent',
    'bhara',
  ]),
  SeedItem(
    'electricity',
    'ইলেক্ট্রিসিটি বিল',
    'Electricity bill',
    'fixed_bills',
    Unit.piece,
    ['bidyut', 'current'],
  ),
  SeedItem(
    'internet',
    'ইন্টারনেট বিল',
    'Internet bill',
    'fixed_bills',
    Unit.piece,
    ['wifi'],
  ),
  SeedItem('garbage', 'ময়লার বিল', 'Garbage bill', 'fixed_bills', Unit.piece, [
    'moyla',
  ]),
  SeedItem('dish_bar', 'ভিমবার', 'Dish-wash bar', 'other', Unit.piece, ['vim']),
  SeedItem('hair_oil', 'প্যারাসুট তেল', 'Hair oil', 'other', Unit.piece, [
    'parachute',
  ]),
];
