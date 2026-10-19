/// What a document listener knows about one document.
///
/// Firestore reports a document that is not in the local cache as
/// `exists == false` with `metadata.isFromCache == true`.  That means
/// "unknown yet", NOT "absent": routing on it would send a signed-in user to
/// profile setup or family choice just because the phone is offline.
sealed class DocState<T> {
  const DocState();

  /// The value when present, otherwise null.
  T? get valueOrNull => switch (this) {
        DocPresent<T>(:final value) => value,
        _ => null,
      };
}

/// Not in the cache and the server has not answered yet.
final class DocUnknown<T> extends DocState<T> {
  const DocUnknown();

  @override
  bool operator ==(Object other) => other is DocUnknown<T>;

  @override
  int get hashCode => 0x1;
}

/// The server confirmed the document does not exist.
final class DocAbsent<T> extends DocState<T> {
  const DocAbsent();

  @override
  bool operator ==(Object other) => other is DocAbsent<T>;

  @override
  int get hashCode => 0x2;
}

/// The document exists (from the cache or the server).
final class DocPresent<T> extends DocState<T> {
  const DocPresent(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is DocPresent<T> && other.value == value;

  @override
  int get hashCode => Object.hash(0x3, value);
}

/// Pure mapping from snapshot facts to a [DocState].
DocState<Map<String, dynamic>> docStateOf({
  required bool exists,
  required bool isFromCache,
  required Map<String, dynamic>? data,
}) {
  if (exists && data != null) return DocPresent<Map<String, dynamic>>(data);
  if (isFromCache) return const DocUnknown<Map<String, dynamic>>();
  return const DocAbsent<Map<String, dynamic>>();
}
