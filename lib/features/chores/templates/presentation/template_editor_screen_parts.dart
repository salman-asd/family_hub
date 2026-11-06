part of 'template_editor_screen.dart';

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.actionKey,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.warning, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: t.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: t.textPrimary),
                ),
                if (actionLabel != null)
                  TextButton(
                    key: actionKey,
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.failure,
    required this.saving,
    required this.canSave,
    required this.onSave,
  });

  final AppFailure? failure;
  final bool saving;
  final bool canSave;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final f = failure;
    return Material(
      color: t.surfaceRaised,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (f != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: t.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.choresFailureMessage(f),
                          key: const ValueKey<String>('editor_failure'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: t.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              BusyButton(
                key: const ValueKey<String>('editor_save'),
                label: l10n.actionSave,
                busy: saving,
                busyLabel: l10n.loadingSemantics,
                onPressed: canSave ? () => onSave() : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
