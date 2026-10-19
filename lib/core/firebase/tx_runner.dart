import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/firebase/sync_status.dart';

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

  @override
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    _batch.set(_firestore.doc(path), data, SetOptions(merge: merge));
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    _batch.update(_firestore.doc(path), data);
  }

  @override
  void delete(String path) {
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
    _transaction.set(_firestore.doc(path), data, SetOptions(merge: merge));
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    _transaction.update(_firestore.doc(path), data);
  }

  @override
  void delete(String path) {
    _transaction.delete(_firestore.doc(path));
  }
}

/// In-memory fake implementation of [TxRunner] for fast unit and use-case tests.
class FakeTxRunner implements TxRunner {
  FakeTxRunner([Map<String, Map<String, dynamic>>? initialStore])
      : store = initialStore != null
            ? Map<String, Map<String, dynamic>>.from(
                initialStore
                    .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
              )
            : <String, Map<String, dynamic>>{};

  /// In-memory document storage: path -> fields map.
  final Map<String, Map<String, dynamic>> store;

  /// Same counter the real runner exposes, so widget tests can drive the banner.
  final PendingWriteCounter pendingWrites = PendingWriteCounter();

  /// Tests: when set, the next commit waits for it (simulates being offline).
  Future<void>? holdNextCommit;

  /// Tests: when set, the next batch throws this and writes nothing.
  Object? failNextBatchWith;

  @override
  Future<void> runBatch(
    FutureOr<void> Function(BatchContext batch) action,
  ) async {
    final pendingOps = <_PendingOp>[];
    final context = _FakeBatchContext(pendingOps);
    await action(context);

    await pendingWrites.track(() async {
      final failure = failNextBatchWith;
      if (failure != null) {
        failNextBatchWith = null;
        throw failure;
      }
      final hold = holdNextCommit;
      if (hold != null) {
        holdNextCommit = null;
        await hold;
      }
      // Atomically commit staged operations
      for (final op in pendingOps) {
        op.apply(store);
      }
    });
  }

  @override
  Future<T> runTransaction<T>(
    FutureOr<T> Function(TransactionContext tx) action, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final pendingOps = <_PendingOp>[];
    final context = _FakeTransactionContext(store, pendingOps);
    final result = await action(context);

    // Atomically commit staged operations
    for (final op in pendingOps) {
      op.apply(store);
    }
    return result;
  }
}

abstract class _PendingOp {
  void apply(Map<String, Map<String, dynamic>> store);
}

class _SetOp implements _PendingOp {
  _SetOp(this.path, this.data, this.merge);

  final String path;
  final Map<String, dynamic> data;
  final bool merge;

  @override
  void apply(Map<String, Map<String, dynamic>> store) {
    if (merge && store.containsKey(path)) {
      store[path] = <String, dynamic>{
        ...store[path]!,
        ...data,
      };
    } else {
      store[path] = Map<String, dynamic>.from(data);
    }
  }
}

class _UpdateOp implements _PendingOp {
  _UpdateOp(this.path, this.data);

  final String path;
  final Map<String, dynamic> data;

  @override
  void apply(Map<String, Map<String, dynamic>> store) {
    if (!store.containsKey(path)) {
      throw StateError('Cannot update non-existent document at $path');
    }
    store[path] = <String, dynamic>{
      ...store[path]!,
      ...data,
    };
  }
}

class _DeleteOp implements _PendingOp {
  _DeleteOp(this.path);

  final String path;

  @override
  void apply(Map<String, Map<String, dynamic>> store) {
    store.remove(path);
  }
}

class _FakeBatchContext implements BatchContext {
  _FakeBatchContext(this._pendingOps);

  final List<_PendingOp> _pendingOps;

  @override
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    _pendingOps.add(_SetOp(path, data, merge));
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    _pendingOps.add(_UpdateOp(path, data));
  }

  @override
  void delete(String path) {
    _pendingOps.add(_DeleteOp(path));
  }
}

class _FakeTransactionContext implements TransactionContext {
  _FakeTransactionContext(this._store, this._pendingOps);

  final Map<String, Map<String, dynamic>> _store;
  final List<_PendingOp> _pendingOps;

  @override
  Future<Map<String, dynamic>?> get(String path) async {
    // Check locally staged ops first (read-your-own-writes)
    for (final op in _pendingOps.reversed) {
      if (op is _SetOp && op.path == path) {
        return Map<String, dynamic>.from(op.data);
      }
      if (op is _DeleteOp && op.path == path) {
        return null;
      }
    }
    final existing = _store[path];
    if (existing == null) return null;
    return Map<String, dynamic>.from(existing);
  }

  @override
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    _pendingOps.add(_SetOp(path, data, merge));
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    _pendingOps.add(_UpdateOp(path, data));
  }

  @override
  void delete(String path) {
    _pendingOps.add(_DeleteOp(path));
  }
}
