import 'package:flutter/foundation.dart';

/// Marker for "the server decides this timestamp" inside a write map (H5).
///
/// A pure value object: it carries no Firestore type, so the domain and data
/// mappers that build a write can use it and unit tests stay fast.
/// [FirestoreTxRunner] converts it to `FieldValue.serverTimestamp()` and
/// [FakeTxRunner] to the injected clock, so a log's `recordedAt` can never be a
/// forged device clock (CLAUDE.md rule 18/20).
@immutable
class ServerTime {
  const ServerTime._();

  /// The one and only instance; compare with `identical`.
  static const ServerTime instance = ServerTime._();

  @override
  bool operator ==(Object other) => other is ServerTime;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'ServerTime()';
}
