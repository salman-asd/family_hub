import 'package:family_hub/core/firebase/paged_read.dart';
import 'package:flutter_test/flutter_test.dart';

/// B-09: a page boundary that falls in the middle of a day must neither skip
/// nor repeat a document. The cursor is "the last document", never "the last
/// dateKey".
void main() {
  /// 1,000 documents, three per day, ordered by (dateKey, id) like the query.
  final docs = <({String id, String dateKey})>[
    for (var i = 0; i < 1000; i++)
      (
        id: 'tpl_${(i % 3)}_${(i ~/ 3).toString().padLeft(4, '0')}',
        dateKey: '2026-${(i ~/ 90 + 1).toString().padLeft(2, '0')}-'
            '${((i ~/ 3) % 30 + 1).toString().padLeft(2, '0')}',
      ),
  ]..sort((a, b) {
      final byDay = a.dateKey.compareTo(b.dateKey);
      return byDay != 0 ? byDay : a.id.compareTo(b.id);
    });

  var fetches = 0;

  /// The fake query: `startAfterDocument(cursor).limit(size)`; the cursor is
  /// the index of the last document already read.
  Future<PageResult<String, int>> Function(int?) fakeFetch(
    List<({String id, String dateKey})> source,
    int size,
  ) => (after) async {
    fetches++;
    final from = after == null ? 0 : after + 1;
    final slice = source.skip(from).take(size).toList();
    return PageResult<String, int>(
      items: <String>[for (final doc in slice) doc.id],
      fetched: slice.length,
      cursor: slice.isEmpty ? null : from + slice.length - 1,
    );
  };

  setUp(() => fetches = 0);

  test('1,000 docs, 3 per day, page size 400: every id exactly once', () async {
    final ids = await readAllPages<String, int>(
      pageSize: 400,
      fetch: fakeFetch(docs, 400),
    );

    expect(ids, hasLength(1000));
    expect(ids.toSet(), hasLength(1000));
    expect(ids, <String>[for (final doc in docs) doc.id]);
    expect(fetches, 3, reason: '400 + 400 + 200');
    // 400 is not a multiple of 3: the first page really ends mid-day.
    expect(docs[399].dateKey, docs[400].dateKey);
  });

  test('a result that is an exact multiple of the page size stops cleanly',
      () async {
    final ids = await readAllPages<String, int>(
      pageSize: 400,
      fetch: fakeFetch(docs.take(800).toList(), 400),
    );

    expect(ids, hasLength(800));
    expect(fetches, 3, reason: 'the third page is empty and ends the loop');
  });

  test('an empty and a short result need one fetch', () async {
    expect(
      await readAllPages<String, int>(
        pageSize: 400,
        fetch: fakeFetch(const [], 400),
      ),
      isEmpty,
    );
    expect(fetches, 1);

    fetches = 0;
    expect(
      await readAllPages<String, int>(
        pageSize: 400,
        fetch: fakeFetch(docs.take(10).toList(), 400),
      ),
      hasLength(10),
    );
    expect(fetches, 1);
  });

  test('documents the mapper drops still count towards the page', () async {
    // 400 raw documents per page, but only the even ones map to an item.
    final ids = await readAllPages<String, int>(
      pageSize: 400,
      fetch: (after) async {
        final page = await fakeFetch(docs, 400)(after);
        return PageResult<String, int>(
          items: <String>[
            for (var i = 0; i < page.items.length; i++)
              if (i.isEven) page.items[i],
          ],
          fetched: page.fetched,
          cursor: page.cursor,
        );
      },
    );

    expect(ids, hasLength(500));
    expect(fetches, 3);
  });
}
