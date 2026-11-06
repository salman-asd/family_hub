import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/firebase/sync_status.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_host.dart';
import 'package:family_hub/features/chores/presentation/chores_generation_hook.dart';
import 'package:family_hub/shared/widgets/pill_bottom_bar.dart';
import 'package:family_hub/shared/widgets/responsive_layout.dart';
import 'package:family_hub/shared/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One tab of the shell: the data the bottom bar needs.
///
/// The shell's branch list and this list are built from the same destinations
/// in `router.dart`, so index `i` here is always branch `i` there.
class ShellDestination {
  const ShellDestination({
    required this.id,
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final String id;
  final IconData icon;
  final IconData? selectedIcon;

  /// Localized label factory, evaluated with the active locale.
  final String Function(BuildContext context) label;
}

/// The app shell: Home, then one tab per module, then Family (Chores and Bazar
/// only while their module is on).  Each tab keeps its own navigation stack and
/// scroll position because go_router hosts the branches in an `IndexedStack`.
///
/// Phones and portrait tablets get the floating [PillBottomBar]; a window wide
/// enough for two panes (P4-24) gets a [NavigationRail] on the leading edge
/// instead.  Only the chrome changes — the same branch is selected, so rotating
/// a tablet keeps the tab and its scroll position.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.destinations,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;

  void _select(int index) => navigationShell.goBranch(
    // Tapping the active tab again returns to the tab's first screen.
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final useRail = context.layoutClass.showsTwoPanes;
    // B-01: generates the chore occurrences once per app start.
    return ChoresGenerationHook(
      child: CelebrationHost(
        child: Scaffold(
          body: Row(
            children: [
              if (useRail)
                _ShellRail(
                  destinations: destinations,
                  selectedIndex: navigationShell.currentIndex,
                  onSelected: _select,
                ),
              Expanded(child: navigationShell),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shown only while changes wait for the server (H3 / rule 15).
              Consumer(
                builder: (context, ref, _) {
                  final status = ref.watch(syncStatusProvider);
                  return SyncBanner(
                    pendingWrites: status.pendingWrites,
                    offline: status.isOffline,
                  );
                },
              ),
              if (!useRail)
                PillBottomBar(
                  selectedIndex: navigationShell.currentIndex,
                  items: [
                    for (final d in destinations)
                      PillNavItem(
                        key: Key('tab_${d.id}'),
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: d.label(context),
                      ),
                  ],
                  onSelected: _select,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tablet tab bar: icon + label per destination, the selected one marked by
/// the indicator, its colour and its [ShellDestination.selectedIcon].
class _ShellRail extends StatelessWidget {
  const _ShellRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Wide enough that a Bangla label at 200 % text still fits (rule 13).
  static const double _width = 124;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final labelText = Theme.of(context).textTheme.labelMedium;
    return SafeArea(
      right: false,
      child: NavigationRail(
        key: const Key('shell_rail'),
        minWidth: _width,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        labelType: NavigationRailLabelType.all,
        backgroundColor: t.surfaceRaised,
        indicatorColor: t.accentSoft,
        selectedIconTheme: IconThemeData(color: t.accentStrong, size: 24),
        unselectedIconTheme: IconThemeData(color: t.textSecondary, size: 24),
        selectedLabelTextStyle: labelText?.copyWith(
          color: t.accentStrong,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: labelText?.copyWith(color: t.textSecondary),
        destinations: [
          for (final d in destinations)
            NavigationRailDestination(
              icon: Icon(d.icon, key: Key('rail_${d.id}')),
              selectedIcon: Icon(d.selectedIcon ?? d.icon),
              label: Text(d.label(context), textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
