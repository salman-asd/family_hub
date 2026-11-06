import 'dart:developer' as developer;

import 'package:family_hub/core/notifications/domain/notification_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class ReminderDiagnostics {
  const ReminderDiagnostics({
    this.lastError,
    this.lastStackTrace,
    this.pendingCount = 0,
    this.lastSyncAt,
  });

  final String? lastError;
  final StackTrace? lastStackTrace;
  final int pendingCount;
  final DateTime? lastSyncAt;

  ReminderDiagnostics copyWith({
    String? lastError,
    StackTrace? lastStackTrace,
    int? pendingCount,
    DateTime? lastSyncAt,
    bool clearError = false,
  }) => ReminderDiagnostics(
    lastError: clearError ? null : (lastError ?? this.lastError),
    lastStackTrace: clearError ? null : (lastStackTrace ?? this.lastStackTrace),
    pendingCount: pendingCount ?? this.pendingCount,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
  );
}

final class ReminderDiagnosticsController
    extends Notifier<ReminderDiagnostics> {
  @override
  ReminderDiagnostics build() => const ReminderDiagnostics();

  void recordError(Object error, StackTrace stackTrace) {
    developer.log(
      'Reminder synchronization failed',
      name: 'family_hub',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    state = state.copyWith(
      lastError: error.toString(),
      lastStackTrace: stackTrace,
    );
  }

  void recordSync(int pendingCount, DateTime at) {
    state = state.copyWith(
      pendingCount: pendingCount,
      lastSyncAt: at,
      clearError: true,
    );
  }
}
