import 'dart:async';

const Duration kStatsSyncDebounce = Duration(seconds: 3);
const Duration kStatsResumeThrottle = Duration(minutes: 10);

final class StatsSyncController {
  StatsSyncController({
    required this.sync,
    required this.onError,
    this.debounce = kStatsSyncDebounce,
    this.resumeThrottle = kStatsResumeThrottle,
  });

  final Future<void> Function() sync;
  final void Function(Object error, StackTrace stackTrace) onError;
  final Duration debounce;
  final Duration resumeThrottle;

  Timer? _timer;
  DateTime? _lastResume;
  bool _disposed = false;
  bool _running = false;
  bool _rerunRequested = false;

  void schedule() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      _timer = null;
      unawaited(_run());
    });
  }

  void onResumed(DateTime now) {
    if (_disposed ||
        (_lastResume != null &&
            now.difference(_lastResume!) < resumeThrottle)) {
      return;
    }
    _lastResume = now;
    _timer?.cancel();
    _timer = null;
    unawaited(_run());
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _run() async {
    if (_running) {
      _rerunRequested = true;
      return;
    }
    _running = true;
    try {
      do {
        _rerunRequested = false;
        try {
          await sync();
        } on Object catch (error, stackTrace) {
          onError(error, stackTrace);
        }
      } while (!_disposed && _rerunRequested);
    } finally {
      _running = false;
    }
  }
}
