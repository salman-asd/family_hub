import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/firebase/server_time.dart';
import 'package:family_hub/core/firebase/sync_status.dart';

export 'package:family_hub/core/firebase/fake_tx_runner.dart';

/// Replaces every top-level [ServerTime] value with `FieldValue.serverTimestamp()`.
///
/// Only the top level is scanned: [ServerTime] is a document-field marker, and
/// every writer puts `recordedAt` at the top level.
Map<String, dynamic> _withServerTimestamps(Map<String, dynamic> data) {
  if (!data.values.any((v) => v is ServerTime)) return data;
  return <String, dynamic>{
    for (final entry in data.entries)
      entry.key: entry.value is ServerTime
          ? FieldValue.serverTimestamp()
          : entry.value,
  };
}

/// Firestore allows at most 500 writes in one batch (H12).  Staging more throws
/// a [StateError] at once, in tests and in production, instead of failing at
/// commit time with a vague backend error.
const int kMaxBatchWrites = 500;

/// Counts staged operations and enforces [kMaxBatchWrites].
class BatchBudget {
  int _used = 0;

  /// How many operations were staged so far.
  int get used => _used;

  void spend() {
    if (++_used > kMaxBatchWrites) {
      throw StateError(
        'A batch may hold at most $kMaxBatchWrites writes; split the work.',
      );
    }
  }
}

/// Context for staging atomic batch writes.
abstract class BatchContext {
  /// Sets [data] on document at [path].
  void set(String path, Map<String, dynamic> data, {bool merge = false});

  /// Updates existing document at [path] with [data].
  void update(String path, Map<String, dynamic> data);

  /// Deletes document at [path].
  void delete(String path);
}

/// Context for atomic transactions (reads followed by staged writes).
abstract class TransactionContext {
  /// Reads document at [path]. Returns null if document does not exist.
  Future<Map<String, dynamic>?> get(String path);

  /// Sets [data] on document at [path].
  void set(String path, Map<String, dynamic> data, {bool merge = false});

  /// Updates existing document at [path] with [data].
  void update(String path, Map<String, dynamic> data);

  /// Deletes document at [path].
  void delete(String path);
}

/// Unit of work interface for atomic Firestore writes.
///
/// Encapsulates multi-document batches and transactions (e.g. creating an expense,
/// writing fund transaction, and updating item in one atomic batch).
abstract class TxRunner {
  /// Runs [action] inside an atomic batch.
  Future<void> runBatch(FutureOr<void> Function(BatchContext batch) action);

  /// Runs [action] inside an atomic transaction.
  Future<T> runTransaction<T>(
    FutureOr<T> Function(TransactionContext tx) action, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  });
}

/// Production implementation of [TxRunner] backed by Cloud Firestore.
class FirestoreTxRunner implements TxRunner {
  FirestoreTxRunner({
    FirebaseFirestore? firestore,
    PendingWriteCounter? pendingWrites,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        pendingWrites = pendingWrites ?? PendingWriteCounter();

  final FirebaseFirestore _firestore;

  /// Commits sent but not yet acknowledged by the server (drives the banner).
  final PendingWriteCounter pendingWrites;

  @override
  Future<void> runBatch(
    FutureOr<void> Function(BatchContext batch) action,
  ) async {
    final writeBatch = _firestore.batch();
    final context = _FirestoreBatchContext(_firestore, writeBatch);
    await action(context);
    await pendingWrites.track(writeBatch.commit);
  }

  @override
  Future<T> runTransaction<T>(
    FutureOr<T> Function(TransactionContext tx) action, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    return _firestore.runTransaction<T>(
      (transaction) async {
        final context = _FirestoreTransactionContext(_firestore, transaction);
        return await action(context);
      },
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}

class _FirestoreBatchContext implements BatchContext {
  _FirestoreBatchContext(this._firestore, this._batch);

  final FirebaseFirestore _firestore;
  final WriteBatch _batch;
  final BatchBudget _budget = BatchBudget();

  @override
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    _budget.spend();
    _batch.set(
      _firestore.doc(path),
      _withServerTimestamps(data),
      SetOptions(merge: merge),
    );
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    _budget.spend();
    _batch.update(_firestore.doc(path), _withServerTimestamps(data));
  }

  @override
  void delete(String path) {
    _budget.spend();
    _batch.delete(_firestore.doc(path));
  }
}

class _FirestoreTransactionContext implements TransactionContext {
  _FirestoreTransactionContext(this._firestore, this._transaction);

  final FirebaseFirestore _firestore;
  final Transaction _transaction;

  @override
  Future<Map<String, dynamic>?> get(String path) async {
    final snapshot = await _transaction.get(_firestore.doc(path));
    if (!snapshot.exists) return null;
    return snapshot.data();
  }

  @override
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    _transaction.set(
      _firestore.doc(path),
      _withServerTimestamps(data),
      SetOptions(merge: merge),
    );
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    _transaction.update(_firestore.doc(path), _withServerTimestamps(data));
  }

  @override
  void delete(String path) {
    _transaction.delete(_firestore.doc(path));
  }
}
