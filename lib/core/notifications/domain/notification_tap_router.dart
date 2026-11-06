final class NotificationTapRouter {
  void Function(String)? _navigate;
  String? _pendingPayload;
  String? _pendingPushPayload;
  bool _choresEnabled = true;
  bool _bazarEnabled = true;

  void attach({
    required void Function(String route) navigate,
    required bool choresEnabled,
    required bool bazarEnabled,
  }) {
    _navigate = navigate;
    _choresEnabled = choresEnabled;
    _bazarEnabled = bazarEnabled;
    final pending = _pendingPayload;
    final pendingPush = _pendingPushPayload;
    _pendingPayload = null;
    _pendingPushPayload = null;
    if (pending != null) route(pending);
    if (pendingPush != null) routePush(pendingPush);
  }

  void route(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final navigate = _navigate;
    if (navigate == null) {
      _pendingPayload = payload;
      return;
    }

    final resolved = resolve(
      payload,
      choresEnabled: _choresEnabled,
      bazarEnabled: _bazarEnabled,
    );
    if (resolved != null) navigate(resolved);
  }

  void routePush(String? payload) {
    final route = payload ?? '';
    final navigate = _navigate;
    if (navigate == null) {
      _pendingPushPayload = route;
      return;
    }

    navigate(
      resolve(
            route,
            choresEnabled: _choresEnabled,
            bazarEnabled: _bazarEnabled,
          ) ??
          '/home',
    );
  }

  static String? resolve(
    String payload, {
    required bool choresEnabled,
    required bool bazarEnabled,
  }) {
    final uri = Uri.tryParse(payload);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        !payload.startsWith('/') ||
        payload.startsWith('//') ||
        uri.pathSegments.any((segment) => segment == '.' || segment == '..')) {
      return null;
    }

    const allowedPrefixes = <String>[
      '/chores',
      '/bazar',
      '/inbox',
      '/activity',
      '/settings/notifications',
    ];
    final allowed = allowedPrefixes.any(
      (prefix) => uri.path == prefix || uri.path.startsWith('$prefix/'),
    );
    if (!allowed) return null;
    if ((!choresEnabled && uri.path.startsWith('/chores')) ||
        (!bazarEnabled && uri.path.startsWith('/bazar'))) {
      return '/home';
    }
    return uri.path;
  }
}
