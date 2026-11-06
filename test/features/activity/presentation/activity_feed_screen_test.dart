import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';
import 'package:family_hub/features/activity/domain/activity_repository.dart';
import 'package:family_hub/features/activity/presentation/activity_feed_screen.dart';
import 'package:family_hub/features/activity/presentation/activity_providers.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/activity_tile.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('fits at 200% text scale in ${locale.languageCode}', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeActivityRepository(),
        locale: locale,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loads older pages without adding another live listener', (
    tester,
  ) async {
    final repository = _FakeActivityRepository();
    await _pump(tester, repository);

    expect(find.byType(ActivityTile), findsOneWidget);
    expect(repository.watchActors, [null]);
    await tester.tap(find.byKey(const Key('activity_load_more')));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityTile), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('activity_load_more')));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityTile), findsNWidgets(3));
    expect(repository.watchActors, [null]);
    expect(repository.olderCursors, ['cursor-1', 'cursor-2']);
  });

  testWidgets('member selection applies the server-side actor filter', (
    tester,
  ) async {
    final repository = _FakeActivityRepository();
    await _pump(tester, repository, withMember: true);

    await tester.tap(find.byKey(const Key('activity_actor_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rina').last);
    await tester.pumpAndSettle();

    expect(repository.watchActors, contains('member-1'));
  });

  testWidgets('shows a retryable offline/read error', (tester) async {
    final repository = _FakeActivityRepository(failFirstPage: true);
    await _pump(tester, repository);

    expect(find.byType(ErrorView), findsOneWidget);
    expect(
      find.text(
        'Could not load activity. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('retries a failed older page', (tester) async {
    final repository = _FakeActivityRepository(failOlderPage: true);
    await _pump(tester, repository);

    await tester.tap(find.byKey(const Key('activity_load_more')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Could not load activity. Check your connection and try again.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('activity_retry_load_more')));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityTile), findsNWidgets(2));
  });
}

Future<void> _pump(
  WidgetTester tester,
  _FakeActivityRepository repository, {
  bool withMember = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = const Size(320, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        activityRepositoryProvider.overrideWithValue(repository),
        currentFamilyIdProvider.overrideWith((ref) => 'family-1'),
        membersProvider.overrideWith(
          (ref) => Stream.value(
            withMember
                ? const <Member>[
                    Member(
                      uid: 'member-1',
                      role: MemberRole.member,
                      status: MembershipStatus.active,
                      fullName: 'Rina Das',
                      nickname: 'Rina',
                      relationship: 'sister',
                    ),
                  ]
                : const <Member>[],
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        theme: buildThemeData(appThemes.firstWhere((theme) => theme.available)),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ActivityFeedScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeActivityRepository implements ActivityRepository {
  _FakeActivityRepository({
    this.failFirstPage = false,
    this.failOlderPage = false,
  });

  final bool failFirstPage;
  final bool failOlderPage;
  final List<String?> watchActors = <String?>[];
  int olderReads = 0;
  final List<String> olderCursors = <String>[];

  static final _first = ActivityEntry(
    id: 'event-1',
    type: 'future.changed',
    actorId: 'member-1',
    params: const {},
    refType: 'futureRef',
    refId: 'target-1',
    createdAt: DateTime.utc(2026, 11, 6),
  );
  static final _older = ActivityEntry(
    id: 'event-2',
    type: 'future.changed',
    actorId: 'member-1',
    params: const {},
    refType: 'futureRef',
    refId: 'target-2',
    createdAt: DateTime.utc(2026, 11, 5),
  );
  static final _oldest = ActivityEntry(
    id: 'event-3',
    type: 'future.changed',
    actorId: 'member-1',
    params: const {},
    refType: 'futureRef',
    refId: 'target-3',
    createdAt: DateTime.utc(2026, 11, 4),
  );

  @override
  Stream<List<ActivityEntry>> watchRecent(
    String familyId, {
    required int limit,
  }) => Stream.value(const <ActivityEntry>[]);

  @override
  Stream<ActivityPage> watchFirstPage(
    String familyId, {
    String? actorId,
    required int limit,
  }) {
    watchActors.add(actorId);
    if (failFirstPage) return Stream.error(StateError('offline'));
    return Stream.value(
      ActivityPage(entries: [_first], cursorId: 'cursor-1', hasMore: true),
    );
  }

  @override
  Future<Result<ActivityPage>> readOlderPage(
    String familyId, {
    String? actorId,
    required String afterDocumentId,
    required int limit,
  }) async {
    olderReads++;
    olderCursors.add(afterDocumentId);
    if (failOlderPage && olderReads == 1) {
      return const Failure<ActivityPage>(Network());
    }
    return olderReads == 1
        ? Success<ActivityPage>(
            ActivityPage(
              entries: [_older],
              cursorId: 'cursor-2',
              hasMore: true,
            ),
          )
        : Success<ActivityPage>(
            ActivityPage(
              entries: [_oldest],
              cursorId: 'cursor-3',
              hasMore: false,
            ),
          );
  }
}
