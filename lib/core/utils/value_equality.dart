/// Value equality for the plain maps and lists a write plan is made of.
///
/// Dart compares `Map` and `List` by identity, but these collections are data,
/// not owners: the same subtask tick built by two code paths is two equal-but-
/// distinct maps, so an object holding one has to look inside instead of at it.
bool sameValue(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map<Object?, Object?> && b is Map<Object?, Object?>) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || !sameValue(b[entry.key], entry.value)) {
        return false;
      }
    }
    return true;
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!sameValue(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// A hash matching [sameValue], so equal values hash equal whatever their order.
int hashValue(Object? value) {
  if (value is Map<Object?, Object?>) {
    return Object.hashAllUnordered(
      value.entries.map(
        (entry) => Object.hash(entry.key, hashValue(entry.value)),
      ),
    );
  }
  if (value is List<Object?>) {
    return Object.hashAll(value.map(hashValue));
  }
  return value.hashCode;
}
