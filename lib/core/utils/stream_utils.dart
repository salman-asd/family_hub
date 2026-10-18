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
