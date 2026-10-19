import 'dart:async';

import 'package:family_hub/core/utils/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Number of commits that have been sent to Firestore but not yet acknowledged
/// by the server.  Offline, a commit stays pending until the connection returns.
class PendingWriteCounter extends ValueNotifier<int> {
  PendingWriteCounter() : super(0);

  /// Runs [operation] and counts it as pending until it completes (or fails).
  Future<T> track<T>(Future<T> Function() operation) async {
    value++;
    try {
      return await operation();
    } finally {
      value--;
    }
  }
}

/// What the sync banner shows.
@immutable
class SyncStatus {
  const SyncStatus({this.pendingWrites = 0, this.offlineSince});

  final int pendingWrites;

  /// Set once writes have been pending longer than [SyncStatusNotifier.grace].
  final DateTime? offlineSince;

  bool get isOffline => offlineSince != null;
  bool get visible => pendingWrites > 0;

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.pendingWrites == pendingWrites &&
      other.offlineSince == offlineSince;

  @override
  int get hashCode => Object.hash(pendingWrites, offlineSince);
}

/// The one counter shared by the Firestore runner and the banner.
/// `bootstrap.dart` overrides it with the runner's counter.
final pendingWriteCounterProvider = Provider<PendingWriteCounter>((ref) {
  final counter = PendingWriteCounter();
  ref.onDispose(counter.dispose);
  return counter;
});

final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);

/// Pending writes for longer than [grace] are reported as "offline": a healthy
/// connection acknowledges a commit within a second or two.
class SyncStatusNotifier extends Notifier<SyncStatus> {
  static const Duration grace = Duration(seconds: 10);

  Timer? _timer;

  @override
  SyncStatus build() {
    final counter = ref.watch(pendingWriteCounterProvider);
    void onChange() => _update(counter.value);
    counter.addListener(onChange);
    ref.onDispose(() {
      counter.removeListener(onChange);
      _timer?.cancel();
    });
    return SyncStatus(pendingWrites: counter.value);
  }

  void _update(int pending) {
    if (pending == 0) {
      _timer?.cancel();
      _timer = null;
      state = const SyncStatus();
      return;
    }
    state = SyncStatus(
      pendingWrites: pending,
      offlineSince: state.offlineSince,
    );
    _timer ??= Timer(grace, () {
      _timer = null;
      final counter = ref.read(pendingWriteCounterProvider);
      if (counter.value > 0) {
        state = SyncStatus(
          pendingWrites: counter.value,
          offlineSince: ref.read(clockProvider).nowUtc(),
        );
      }
    });
  }
}
