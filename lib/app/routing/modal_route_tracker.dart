import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final modalRouteTrackerProvider = Provider<ModalRouteTracker>((ref) {
  final tracker = ModalRouteTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});

final class ModalRouteTracker extends ChangeNotifier {
  final Set<Route<dynamic>> _routes = HashSet<Route<dynamic>>.identity();

  bool get hasOpenModalRoute => _routes.isNotEmpty;

  NavigatorObserver createObserver() => _TrackedModalRouteObserver(this);

  void _didPush(Route<dynamic> route) {
    if (route is PopupRoute<dynamic> && _routes.add(route)) notifyListeners();
  }

  void _didRemove(Route<dynamic> route) {
    if (_routes.remove(route)) notifyListeners();
  }

  void _didReplace(Route<dynamic>? oldRoute, Route<dynamic>? newRoute) {
    var changed = false;
    if (oldRoute != null) changed = _routes.remove(oldRoute);
    if (newRoute is PopupRoute<dynamic>) {
      changed = _routes.add(newRoute) || changed;
    }
    if (changed) notifyListeners();
  }
}

final class _TrackedModalRouteObserver extends NavigatorObserver {
  _TrackedModalRouteObserver(this.tracker);

  final ModalRouteTracker tracker;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    tracker._didPush(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    tracker._didRemove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    tracker._didRemove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    tracker._didReplace(oldRoute, newRoute);
  }
}
