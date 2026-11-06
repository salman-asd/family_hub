final class PushDiagnostics {
  const PushDiagnostics({
    this.notificationsGranted = false,
    this.tokenRegistered = false,
    this.tokenPrefix,
    this.lastTokenRefresh,
    this.lastReceivedMessage,
    this.lastError,
  });

  final bool notificationsGranted;
  final bool tokenRegistered;
  final String? tokenPrefix;
  final DateTime? lastTokenRefresh;
  final DateTime? lastReceivedMessage;
  final String? lastError;

  PushDiagnostics copyWith({
    bool? notificationsGranted,
    bool? tokenRegistered,
    String? tokenPrefix,
    bool clearTokenPrefix = false,
    DateTime? lastTokenRefresh,
    DateTime? lastReceivedMessage,
    String? lastError,
    bool clearLastError = false,
  }) => PushDiagnostics(
    notificationsGranted: notificationsGranted ?? this.notificationsGranted,
    tokenRegistered: tokenRegistered ?? this.tokenRegistered,
    tokenPrefix: clearTokenPrefix ? null : (tokenPrefix ?? this.tokenPrefix),
    lastTokenRefresh: lastTokenRefresh ?? this.lastTokenRefresh,
    lastReceivedMessage: lastReceivedMessage ?? this.lastReceivedMessage,
    lastError: clearLastError ? null : (lastError ?? this.lastError),
  );

  @override
  bool operator ==(Object other) =>
      other is PushDiagnostics &&
      other.notificationsGranted == notificationsGranted &&
      other.tokenRegistered == tokenRegistered &&
      other.tokenPrefix == tokenPrefix &&
      other.lastTokenRefresh == lastTokenRefresh &&
      other.lastReceivedMessage == lastReceivedMessage &&
      other.lastError == lastError;

  @override
  int get hashCode => Object.hash(
    notificationsGranted,
    tokenRegistered,
    tokenPrefix,
    lastTokenRefresh,
    lastReceivedMessage,
    lastError,
  );
}
