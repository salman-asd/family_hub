import 'package:flutter/material.dart';

/// A [FilledButton] that disables itself and shows a spinner while [busy].
class BusyButton extends StatelessWidget {
  const BusyButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// Screen-reader label while [busy] replaces the visible [label] with a
  /// spinner.  Falls back to no label when omitted.
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(
                width: 22,
                height: 22,
                child: Semantics(
                  label: busyLabel,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Text(label),
      ),
    );
  }
}
