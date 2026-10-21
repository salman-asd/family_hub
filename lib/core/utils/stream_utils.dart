import 'dart:async';

/// Re-maps [source] to an inner stream and always follows the newest one: when
/// [source] emits again the previous inner subscription is cancelled (unlike
/// `asyncExpand`, which would wait for the old inner stream to finish).
///
/// Used to chain "user document -> familyId -> member document" listeners.
Stream<R> switchMap<T, R>(
  Stream<T> source,
  Stream<R> Function(T value) mapper,
) {
  late StreamController<R> controller;
  StreamSubscription<T>? outer;
  StreamSubscription<R>? inner;
  var outerDone = false;

  void maybeClose() {
    if (outerDone && inner == null && !controller.isClosed) {
      unawaited(controller.close());
    }
  }

  controller = StreamController<R>(
    onListen: () {
      outer = source.listen(
        (value) {
          unawaited(inner?.cancel());
          inner = mapper(value).listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              inner = null;
              maybeClose();
            },
          );
        },
        onError: controller.addError,
        onDone: () {
          outerDone = true;
          maybeClose();
        },
      );
    },
    onCancel: () async {
      await inner?.cancel();
      await outer?.cancel();
    },
  );
  return controller.stream;
}

/// Combines three streams (H10).
///
/// Emits [combine] of the latest values once EVERY source has emitted at least
/// once, then again on every later emission of any source.  An error from any
/// source is forwarded.  Cancelling the result cancels all three subscriptions,
/// and the result closes when all sources are done.
///
/// Used by `watchFamily` to follow `families/{f}`, `settings/general` and
/// `settings/modules` without re-reading two of them on every change.
Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A a, B b, C c) combine,
) {
  late StreamController<R> controller;
  final subscriptions = <StreamSubscription<Object?>>[];
  A? latestA;
  B? latestB;
  C? latestC;
  var hasA = false;
  var hasB = false;
  var hasC = false;
  var open = 3;

  void emit() {
    if (hasA && hasB && hasC && !controller.isClosed) {
      controller.add(combine(latestA as A, latestB as B, latestC as C));
    }
  }

  void done() {
    open--;
    if (open == 0 && !controller.isClosed) unawaited(controller.close());
  }

  controller = StreamController<R>(
    onListen: () {
      subscriptions
        ..add(
          a.listen(
            (v) {
              latestA = v;
              hasA = true;
              emit();
            },
            onError: controller.addError,
            onDone: done,
          ),
        )
        ..add(
          b.listen(
            (v) {
              latestB = v;
              hasB = true;
              emit();
            },
            onError: controller.addError,
            onDone: done,
          ),
        )
        ..add(
          c.listen(
            (v) {
              latestC = v;
              hasC = true;
              emit();
            },
            onError: controller.addError,
            onDone: done,
          ),
        );
    },
    onCancel: () async {
      for (final s in subscriptions) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}
