import 'dart:async';

import 'package:family_hub/core/firebase/server_time.dart';
import 'package:family_hub/core/firebase/sync_status.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';

/// Replaces every top-level [ServerTime] value with the [clock]'s "now".
Map<String, dynamic> _resolveServerTimes(
  Map<String, dynamic> data,
  Clock clock,
) {
  if (!data.values.any((v) => v is ServerTime)) return data;
  final now = clock.nowUtc();
  return <String, dynamic>{
    for (final entry in data.entries)
      entry.key: entry.value is ServerTime ? now : entry.value,
  };
}

/// In-memory fake implementation of [TxRunner] for fast unit and use-case tests.
class FakeTxRunner implements TxRunner {
  FakeTxRunner([
    Map<String, Map<String, dynamic>>? initialStore,
    Clock? clock,
  ])  : clock = clock ?? const SystemClock(),
        store = initialStore != null
            ? Map<String, Map<String, dynamic>>.from(
                initialStore
                    .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
              )
            : <String, Map<String, dynamic>>{};

  /// In-memory document storage: path -> fields map.
  final Map<String, Map<String, dynamic>> store;

  /// Resolves [ServerTime] markers (used by the log `recordedAt`).
  final Clock clock;

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
    final context = _FakeBatchContext(pendingOps, clock);
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
    final context = _FakeTransactionContext(store, pendingOps, clock);
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
  _FakeBatchContext(this._pendingOps, this._clock);

  final List<_PendingOp> _pendingOps;
  final Clock _clock;
  final BatchBudget _budget = BatchBudget();

  @override
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    _budget.spend();
    _pendingOps.add(_SetOp(path, _resolveServerTimes(data, _clock), merge));
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    _budget.spend();
    _pendingOps.add(_UpdateOp(path, _resolveServerTimes(data, _clock)));
  }

  @override
  void delete(String path) {
    _budget.spend();
    _pendingOps.add(_DeleteOp(path));
  }
}

class _FakeTransactionContext implements TransactionContext {
  _FakeTransactionContext(this._store, this._pendingOps, this._clock);

  final Map<String, Map<String, dynamic>> _store;
  final List<_PendingOp> _pendingOps;
  final Clock _clock;

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
    _pendingOps.add(_SetOp(path, _resolveServerTimes(data, _clock), merge));
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    _pendingOps.add(_UpdateOp(path, _resolveServerTimes(data, _clock)));
  }

  @override
  void delete(String path) {
    _pendingOps.add(_DeleteOp(path));
  }
}
