import 'dart:async';

/// Counts the live stream subscriptions a test puts under a Riverpod provider.
///
/// A `StreamProvider` holds exactly one subscription while it is alive, so
/// counting here is counting the Firestore listeners the screen would open —
/// which is what the Phase 4 read budget (P4-25) asks for. Every stream is
/// tracked under a name, so a failure says who opened what.
final class ListenerCensus {
  final Map<String, int> _opened = <String, int>{};
  final Map<String, int> _live = <String, int>{};

  /// Live subscriptions right now, all sources together.
  int get live => _live.values.fold(0, (sum, n) => sum + n);

  /// How many times each source was subscribed since the census began.
  Map<String, int> get opened => Map<String, int>.unmodifiable(_opened);

  /// The sources with a live subscription right now.
  Set<String> get liveSources => <String>{
    for (final entry in _live.entries)
      if (entry.value > 0) entry.key,
  };

  /// A one-line summary to put in an assertion message.
  String get report {
    final parts = <String>[
      for (final name in _live.keys.sorted())
        if ((_live[name] ?? 0) > 0) '$name=${_live[name]}',
    ];
    return 'live $live ($parts), opened $_opened';
  }

  /// Wraps [source] so subscribing to it and dropping it counts as [name].
  Stream<T> track<T>(String name, Stream<T> Function() source) {
    late final StreamController<T> out;
    StreamSubscription<T>? inner;
    out = StreamController<T>(
      onListen: () {
        _opened[name] = (_opened[name] ?? 0) + 1;
        _live[name] = (_live[name] ?? 0) + 1;
        inner = source().listen(
          out.add,
          onError: out.addError,
          onDone: out.close,
        );
      },
      onCancel: () {
        _live[name] = (_live[name] ?? 1) - 1;
        return inner?.cancel();
      },
    );
    return out.stream;
  }
}

extension on Iterable<String> {
  List<String> sorted() => <String>[...this]..sort();
}
