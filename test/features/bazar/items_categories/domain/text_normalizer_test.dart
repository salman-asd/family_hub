import 'package:family_hub/features/bazar/items_categories/domain/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trims, lower-cases and collapses whitespace', () {
    expect(normalizeSearch('  Hello   World  '), 'hello world');
    expect(normalizeSearch('\tচাল\nকেজি '), 'চাল কেজি');
  });

  test('removes zero-width joiners and non-joiners', () {
    expect(normalizeSearch('অ\u200D্য\u200Cাভোকাডো'), 'অ্যাভোকাডো');
  });

  test('composes the three Bangla nukta pairs', () {
    expect(normalizeSearch('ড\u09BC'), '\u09DC');
    expect(normalizeSearch('ঢ\u09BC'), '\u09DD');
    expect(normalizeSearch('য\u09BC'), '\u09DF');
  });

  test('composed and decomposed spellings normalize identically', () {
    expect(normalizeSearch('প\u09DCা'), normalizeSearch('পড\u09BCা'));
    expect(normalizeSearch('\u09DD'), normalizeSearch('ঢ\u09BC'));
    expect(normalizeSearch('\u09DF'), normalizeSearch('য\u09BC'));
  });

  test('maps Bangla digits to English ones', () {
    expect(normalizeSearch('চাল ৫০০ গ্রাম'), 'চাল 500 গ্রাম');
    expect(normalizeSearch('১২৩'), '123');
  });

  test('is idempotent', () {
    const input = '  অ\u200D্যাভোকাডো ৫  ';
    final once = normalizeSearch(input);
    expect(normalizeSearch(once), once);
  });

  test('empty and whitespace-only input become the empty string', () {
    expect(normalizeSearch(''), '');
    expect(normalizeSearch(' \t\n '), '');
  });
}
