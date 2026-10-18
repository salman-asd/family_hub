import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/login_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

/// Widget tests for the auth screens.
///
/// The screens are mounted **standalone** (no `go_router`) because that is the
/// only way to assert what a form itself does.  Every widget that navigates
/// also takes an `on...` callback, which is what these tests observe instead of
/// asserting on router state owned by Step 8.
///
/// Each test drives the flow by typing, not by poking the controller, so the
/// wiring between TextField, controller and button is covered too.
void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  /// Mounts [child] with the real theme, Bangla localization and the fake repo.
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('bn'),
  }) async {
    // A real phone surface.  The 800x600 test default is a tablet-ish window
    // that hides wrapping bugs; every one of these screens is phone-first.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildThemeData(defaultLightSpec),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The localized strings, loaded directly so assertions do not hard-code
  /// Bangla text that could drift from the ARB file.
  Future<AppLocalizations> l10nFor(Locale locale) =>
      AppLocalizations.delegate.load(locale);

  group('Welcome', () {
    testWidgets('offers both entry points', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      await pumpScreen(tester, const WelcomeScreen());

      expect(find.text(l10n.authWelcomeHeadline), findsOneWidget);
      expect(find.text(l10n.authGetStarted), findsOneWidget);
      expect(find.text(l10n.authCreateAccountAction), findsOneWidget);
    });

    testWidgets('renders in English too', (tester) async {
      final l10n = await l10nFor(const Locale('en'));
      await pumpScreen(
        tester,
        const WelcomeScreen(),
        locale: const Locale('en'),
      );

      expect(find.text(l10n.authWelcomeHeadline), findsOneWidget);
    });
  });

  group('Login', () {
    testWidgets('a successful sign-in reports it and clears the button',
        (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      var signedIn = false;
      await pumpScreen(
        tester,
        LoginScreen(onSignedIn: () => signedIn = true),
      );

      await tester.enterText(
        find.byType(TextField).first,
        'a@b.co',
      );
      await tester.enterText(find.byType(TextField).last, 'longenough');
      await tester.pump();

      await tester
          .tap(find.widgetWithText(FilledButton, l10n.authSignInAction));
      await tester.pumpAndSettle();

      expect(signedIn, isTrue);
      expect(repository.calls, contains('signIn'));
      expect(repository.lastEmail, 'a@b.co');
    });

    testWidgets('a wrong password shows the localized Bangla message',
        (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      repository.signInFailure = const InvalidCredentials();

      await pumpScreen(tester, const LoginScreen());

      await tester.enterText(find.byType(TextField).first, 'a@b.co');
      await tester.enterText(find.byType(TextField).last, 'longenough');
      await tester.pump();
      await tester
          .tap(find.widgetWithText(FilledButton, l10n.authSignInAction));
      await tester.pumpAndSettle();

      // The copy comes from the ARB file, verified through the same mapping the
      // screen uses — so this fails if the key or the mapping is wrong.
      expect(
        find.text(l10n.authFailureMessage('invalid_credentials')),
        findsOneWidget,
      );
    });

    testWidgets('an invalid email is reported inline and never sent',
        (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      await pumpScreen(tester, const LoginScreen());

      await tester.enterText(find.byType(TextField).first, 'not-an-email');
      await tester.pump();

      expect(
        find.text(l10n.authFailureMessage('validation.email.invalid_email')),
        findsOneWidget,
      );
      expect(repository.calls, isEmpty);
    });

    testWidgets('offline shows the network message', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      repository.signInFailure = const Network();

      await pumpScreen(tester, const LoginScreen());

      await tester.enterText(find.byType(TextField).first, 'a@b.co');
      await tester.enterText(find.byType(TextField).last, 'longenough');
      await tester.pump();
      await tester
          .tap(find.widgetWithText(FilledButton, l10n.authSignInAction));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.authFailureMessage('network')),
        findsOneWidget,
      );
    });

    testWidgets('the submit button is disabled while empty', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      await pumpScreen(tester, const LoginScreen());

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, l10n.authSignInAction),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('the password is obscured and the toggle relabels itself',
        (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      await pumpScreen(tester, const LoginScreen());

      final passwordField = tester.widget<TextField>(
        find.byType(TextField).last,
      );
      expect(passwordField.obscureText, isTrue);
      expect(find.bySemanticsLabel(l10n.authShowPassword), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.authShowPassword));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      expect(find.bySemanticsLabel(l10n.authHidePassword), findsOneWidget);
    });
  });

  group('SignUp', () {
    testWidgets('mismatched passwords are caught before any request',
        (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      await pumpScreen(tester, const SignUpScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'a@b.co');
      await tester.enterText(fields.at(1), 'longenough');
      await tester.enterText(fields.at(2), 'different');
      await tester.pump();

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.authCreateAccountAction),
      );
      await tester.pumpAndSettle();

      expect(repository.calls, isEmpty);
      expect(
        find.text(
          l10n.authFailureMessage(
            'validation.password_confirm.password_mismatch',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a matching form creates the account', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      var signedUp = false;
      await pumpScreen(
        tester,
        SignUpScreen(onSignedUp: () => signedUp = true),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'a@b.co');
      await tester.enterText(fields.at(1), 'longenough');
      await tester.enterText(fields.at(2), 'longenough');
      await tester.pump();

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.authCreateAccountAction),
      );
      await tester.pumpAndSettle();

      expect(signedUp, isTrue);
      expect(repository.calls, contains('signUp'));
    });

    testWidgets('an email already in use is explained', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      repository.signUpFailure = const EmailAlreadyInUse();

      await pumpScreen(tester, const SignUpScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'a@b.co');
      await tester.enterText(fields.at(1), 'longenough');
      await tester.enterText(fields.at(2), 'longenough');
      await tester.pump();

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.authCreateAccountAction),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.authFailureMessage('email_already_in_use')),
        findsOneWidget,
      );
    });
  });

  group('ForgotPassword', () {
    testWidgets('shows a confirmation naming the address', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      await pumpScreen(tester, const ForgotPasswordScreen());

      await tester.enterText(find.byType(TextField).first, 'a@b.co');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.authForgotPasswordSend),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.authForgotPasswordSentTitle), findsOneWidget);
      expect(
        find.text(l10n.authForgotPasswordSentMessage('a@b.co')),
        findsOneWidget,
      );
    });

    testWidgets('a malformed address never reaches the backend',
        (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      await pumpScreen(tester, const ForgotPasswordScreen());

      await tester.enterText(find.byType(TextField).first, 'bad');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.authForgotPasswordSend),
      );
      await tester.pumpAndSettle();

      expect(repository.calls, isEmpty);
    });
  });

  group('VerifyEmail', () {
    testWidgets('explains the still-unverified case informationally',
        (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      repository.signInAs(
        const AppUser(uid: 'u1', email: 'a@b.co', emailVerified: false),
      );

      await pumpScreen(tester, const VerifyEmailScreen());

      await tester.tap(
        find.widgetWithText(
          FilledButton,
          l10n.authVerifyEmailIHaveVerified,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.authVerifyEmailStillUnverified), findsOneWidget);
      // It must NOT be styled as an error: no generic error text is shown.
      expect(find.text(l10n.authFailureMessage('unknown')), findsNothing);
    });

    testWidgets('confirms a successful resend', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      repository.signInAs(
        const AppUser(uid: 'u1', email: 'a@b.co', emailVerified: false),
      );

      await pumpScreen(tester, const VerifyEmailScreen());

      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n.authVerifyEmailResend),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.authEmailVerificationSent), findsOneWidget);
    });

    testWidgets('reports success once the address is verified', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      repository
        ..signInAs(
          const AppUser(uid: 'u1', email: 'a@b.co', emailVerified: false),
        )
        ..reloadVerified = true;

      var verified = false;
      await pumpScreen(
        tester,
        VerifyEmailScreen(onVerified: () => verified = true),
      );

      await tester.tap(
        find.widgetWithText(
          FilledButton,
          l10n.authVerifyEmailIHaveVerified,
        ),
      );
      await tester.pumpAndSettle();

      expect(verified, isTrue);
    });

    testWidgets('signing out from here is possible', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      repository.signInAs(
        const AppUser(uid: 'u1', email: 'a@b.co', emailVerified: false),
      );

      var signedOut = false;
      await pumpScreen(
        tester,
        VerifyEmailScreen(onSignedOut: () => signedOut = true),
      );

      await tester.tap(
        find.widgetWithText(TextButton, l10n.authVerifyEmailSignOutInstead),
      );
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
      expect(repository.calls, contains('signOut'));
    });
  });

  group('accessibility', () {
    testWidgets('login survives a 200% text scale without overflow',
        (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      await pumpScreen(
        tester,
        const MediaQuery(
          // Bangla at double size is the worst realistic case (roadmap Step 5).
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: LoginScreen(),
        ),
      );

      // A RenderFlex overflow is reported through the error handler.
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.authSignInAction), findsWidgets);
    });

    testWidgets('the spinner is announced while signing in', (tester) async {
      final l10n = await l10nFor(const Locale('bn'));
      repository.hold = true;

      await pumpScreen(tester, const LoginScreen());

      await tester.enterText(find.byType(TextField).first, 'a@b.co');
      await tester.enterText(find.byType(TextField).last, 'longenough');
      await tester.pump();

      await tester
          .tap(find.widgetWithText(FilledButton, l10n.authSignInAction));
      await tester.pump();

      // The progress indicator carries the localized loading label, so the
      // in-flight state is not conveyed by the animation alone.
      expect(find.bySemanticsLabel(l10n.loadingGeneric), findsOneWidget);

      repository.release();
      await tester.pumpAndSettle();
    });
  });
}
