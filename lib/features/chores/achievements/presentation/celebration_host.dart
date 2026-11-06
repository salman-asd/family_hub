import 'dart:async';
import 'dart:developer' as developer;

import 'package:family_hub/app/routing/modal_route_tracker.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/celebration_state.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_controller.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_overlay.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class CelebrationHost extends ConsumerStatefulWidget {
  const CelebrationHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<CelebrationHost> createState() => _CelebrationHostState();
}

final class _CelebrationHostState extends ConsumerState<CelebrationHost> {
  late final ProviderSubscription<CelebrationState> _subscription;
  late final ModalRouteTracker _modalRouteTracker;
  CelebrationShown? _pending;
  final Set<({String familyId, DateKey dateKey})> _handledEvents =
      <({String familyId, DateKey dateKey})>{};
  bool _attemptScheduled = false;
  bool _showing = false;
  bool _settingsErrorLogged = false;
  bool _isCurrentRoute = false;
  bool _keyboardOpen = false;

  @override
  void initState() {
    super.initState();
    _modalRouteTracker = ref.read(modalRouteTrackerProvider);
    _modalRouteTracker.addListener(_scheduleAttempt);
    _subscription = ref.listenManual<CelebrationState>(
      celebrationControllerProvider,
      (_, next) {
        if (next case CelebrationShown()) {
          _pending = next;
          _scheduleAttempt();
        }
      },
      fireImmediately: true,
    );
    FocusManager.instance.addListener(_scheduleAttempt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleAttempt();
  }

  @override
  void dispose() {
    _subscription.close();
    _modalRouteTracker.removeListener(_scheduleAttempt);
    FocusManager.instance.removeListener(_scheduleAttempt);
    super.dispose();
  }

  void _scheduleAttempt() {
    if (!mounted || _pending == null || _showing || _attemptScheduled) return;
    _attemptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptScheduled = false;
      if (!mounted || _pending == null || _showing || _isBlocked) return;
      _present(_pending!);
    });
  }

  bool get _isBlocked {
    if (!_isCurrentRoute ||
        _modalRouteTracker.hasOpenModalRoute ||
        _keyboardOpen) {
      return true;
    }
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext?.findAncestorWidgetOfExactType<EditableText>() != null) {
      return true;
    }
    return false;
  }

  void _present(CelebrationShown celebration) {
    final dateKey = celebration.dateKey;
    final familyId = ref.read(currentFamilyIdProvider);
    if (familyId == null) return;
    final settingsState = ref.read(engagementSettingsProvider(familyId));
    if (settingsState.hasError && !_settingsErrorLogged) {
      _settingsErrorLogged = true;
      developer.log(
        'Could not load engagement settings for the celebration overlay.',
        error: settingsState.error,
        stackTrace: settingsState.stackTrace,
        name: 'family_hub.celebration',
      );
    }
    final settings = settingsState.value;
    if (settings == null) return;
    final event = (familyId: familyId, dateKey: dateKey);
    if (!_handledEvents.add(event)) {
      _pending = null;
      return;
    }
    final formatters = ref.read(appFormattersProvider);
    _pending = null;
    _showing = true;
    unawaited(
      HapticFeedback.mediumImpact().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        developer.log(
          'Medium haptic feedback is unavailable.',
          error: error,
          stackTrace: stackTrace,
          name: 'family_hub.celebration',
        );
      }),
    );
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => CelebrationOverlay(
          celebration: celebration,
          settings: settings,
          formatNumber: formatters.number,
        ),
      ).then(
        (_) {
          if (!mounted) return;
          ref.read(celebrationControllerProvider.notifier).acknowledge(dateKey);
          _showing = false;
          _scheduleAttempt();
        },
        onError: (Object error, StackTrace stackTrace) {
          developer.log(
            'Could not present the celebration overlay.',
            error: error,
            stackTrace: stackTrace,
            name: 'family_hub.celebration',
          );
          if (!mounted) return;
          _showing = false;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isCurrentRoute = ModalRoute.of(context)?.isCurrent == true;
    _keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final familyId = ref.watch(currentFamilyIdProvider);
    if (familyId != null) ref.watch(engagementSettingsProvider(familyId));
    if (_pending != null) _scheduleAttempt();
    return widget.child;
  }
}
