/// Route paths owned by the auth feature.
///
/// Declared once, next to the screens, so the router and the screens cannot
/// disagree about a string.
abstract final class AuthRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
}
