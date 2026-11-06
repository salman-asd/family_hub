import 'dart:developer' as developer;

void logCelebrationFailure(
  String message,
  Object? error, {
  StackTrace? stackTrace,
}) {
  developer.log(
    message,
    name: 'family_hub',
    error: error,
    stackTrace: stackTrace,
    level: 1000,
  );
}
