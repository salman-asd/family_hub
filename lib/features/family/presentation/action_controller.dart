import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of a one-shot user action (a form submit or a button).
class ActionState {
  const ActionState({this.busy = false, this.failure});

  final bool busy;
  final AppFailure? failure;

  @override
  bool operator ==(Object other) =>
      other is ActionState && other.busy == busy && other.failure == failure;

  @override
  int get hashCode => Object.hash(busy, failure);
}

/// Runs a use case once at a time and exposes busy / failure.
///
/// Each screen owns its own provider instance of this class, so one screen's
/// error never shows on another.
class ActionController extends Notifier<ActionState> {
  @override
  ActionState build() => const ActionState();

  /// Returns the value on success and `null` on failure (the failure is kept in
  /// [state]).  A second call while busy is ignored.
  Future<T?> run<T>(Future<Result<T>> Function() action) async {
    if (state.busy) return null;
    state = const ActionState(busy: true);
    try {
      final result = await action();
      final failure = result.failureOrNull;
      state = ActionState(failure: failure);
      return failure == null ? result.valueOrNull : null;
    } on Object catch (error) {
      state = ActionState(failure: Unknown(error));
      return null;
    }
  }

  void reset() => state = const ActionState();
}

typedef ActionProvider = NotifierProvider<ActionController, ActionState>;

/// A fresh provider per screen.
ActionProvider newActionProvider() =>
    NotifierProvider<ActionController, ActionState>(ActionController.new);
