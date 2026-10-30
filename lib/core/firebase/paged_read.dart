/// One page of a paged read (B-09).
///
/// [fetched] is the number of RAW documents the page returned, which can be
/// larger than `items.length` when a mapper drops a damaged document; the
/// "was this the last page" decision must use the raw count. [cursor] is the
/// last raw document (a Firestore `DocumentSnapshot` in production), `null`
/// when the page was empty.
final class PageResult<T, C> {
  const PageResult({
    required this.items,
    required this.fetched,
    required this.cursor,
  });

  final List<T> items;
  final int fetched;
  final C? cursor;
}

/// Reads a bounded query to the end, page by page.
///
/// The cursor is the last DOCUMENT of the previous page, never a field value:
/// resuming after "the last `dateKey`" skips every remaining document of that
/// day when a page ends mid-day, and a 3-slot chore has three documents per
/// day (B-09). [fetch] is called with `null` for the first page.
///
/// The loop ends on a page shorter than [pageSize] (or an empty one), so a
/// result that is an exact multiple of the page size costs one extra, empty
/// fetch.
Future<List<T>> readAllPages<T, C>({
  required Future<PageResult<T, C>> Function(C? after) fetch,
  required int pageSize,
}) async {
  final all = <T>[];
  C? after;
  while (true) {
    final page = await fetch(after);
    all.addAll(page.items);
    final cursor = page.cursor;
    if (page.fetched < pageSize || cursor == null) break;
    after = cursor;
  }
  return all;
}
