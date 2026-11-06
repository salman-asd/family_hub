part of 'chore_occurrence.dart';

const Object _unset = Object();

/// `copyWith`'s nullable fields: no argument keeps the value, `null` clears it.
T? _pick<T>(Object? value, T? current) =>
    identical(value, _unset) ? current : value as T?;

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameMap(Map<String, SubtaskDone> a, Map<String, SubtaskDone> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
