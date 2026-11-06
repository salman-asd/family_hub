import 'package:family_hub/core/notifications/domain/notification_tap_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts only allow-listed internal route prefixes', () {
    for (final route in <String>[
      '/chores/today',
      '/chores/occurrence/abc',
      '/bazar/fund',
      '/inbox',
      '/activity',
      '/settings/notifications/help',
    ]) {
      expect(
        NotificationTapRouter.resolve(
          route,
          choresEnabled: true,
          bazarEnabled: true,
        ),
        route,
      );
    }

    for (final route in <String>[
      'https://example.com/chores/today',
      '/choresmalicious',
      '/family/settings',
      '/chores/../settings/security',
      '/bazar/fund?external=1',
    ]) {
      expect(
        NotificationTapRouter.resolve(
          route,
          choresEnabled: true,
          bazarEnabled: true,
        ),
        isNull,
        reason: route,
      );
    }
  });

  test('falls back home when the notification module is disabled', () {
    expect(
      NotificationTapRouter.resolve(
        '/chores/today',
        choresEnabled: false,
        bazarEnabled: true,
      ),
      '/home',
    );
    expect(
      NotificationTapRouter.resolve(
        '/bazar/fund',
        choresEnabled: true,
        bazarEnabled: false,
      ),
      '/home',
    );
  });

  test('warm taps and cold-start taps use the attached router', () {
    final router = NotificationTapRouter();
    final routes = <String>[];
    router.route('/chores/today');
    router.attach(
      navigate: routes.add,
      choresEnabled: true,
      bazarEnabled: true,
    );
    router.route('/bazar/fund');

    expect(routes, <String>['/chores/today', '/bazar/fund']);
  });

  test('push taps fall back home for unknown routes and disabled modules', () {
    final router = NotificationTapRouter();
    final routes = <String>[];
    router.routePush('/unknown/route');
    router.attach(
      navigate: routes.add,
      choresEnabled: false,
      bazarEnabled: true,
    );
    router.routePush('/chores/today');

    expect(routes, <String>['/home', '/home']);
  });
}
