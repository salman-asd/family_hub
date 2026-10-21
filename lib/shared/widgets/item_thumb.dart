import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// Square thumbnail for a bazar item (roadmap 9.7).
///
/// Resolution order: the item's own image, then the category image, then a
/// coloured initial placeholder derived from [id] (same id -> same colour on
/// every screen and launch, matching [AppAvatar]'s stable hash).  A failed
/// image load silently keeps the placeholder, so there is no error text and no
/// flicker.
///
/// Accessibility: [semanticLabel] is announced when provided; otherwise the
/// thumb is decorative.
class ItemThumb extends StatelessWidget {
  const ItemThumb({
    required this.id,
    required this.name,
    this.imageUrl,
    this.categoryImageUrl,
    this.imageProvider,
    this.size = 40,
    this.rounded = false,
    this.semanticLabel,
    super.key,
  });

  final String id;
  final String name;

  /// The item's own image, preferred when present.
  final String? imageUrl;

  /// Category image used when the item has none.
  final String? categoryImageUrl;

  /// Any image source (asset, memory, network); wins over both URLs.
  final ImageProvider? imageProvider;

  final double size;

  /// Rounded square (default) vs a full circle.
  final bool rounded;

  /// Localized screen-reader label.  Null makes the thumb decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.tokens.placeholderPalette;
    final index = _stableHash(id) % palette.length;
    final background = palette[index];
    final foreground = AppAvatar.foregroundFor(background, context.tokens);

    final placeholder = _Initials(
      initial: _initialOf(name),
      background: background,
      foreground: foreground,
      size: size,
    );

    final provider = _resolveProvider();
    final child = provider == null
        ? placeholder
        : Stack(
            fit: StackFit.expand,
            children: [
              placeholder,
              Image(
                image: provider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                frameBuilder: (_, widget, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return widget;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: context.tokens.durationFast,
                    curve: context.tokens.curveStandard,
                    child: widget,
                  );
                },
              ),
            ],
          );

    final shape = rounded ? BoxShape.circle : BoxShape.rectangle;
    final clipped = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        shape: shape,
        borderRadius:
            rounded ? null : BorderRadius.circular(context.tokens.radiusSm),
      ),
      child: child,
    );

    if (semanticLabel == null) return ExcludeSemantics(child: clipped);
    // excludeSemantics: announce the item once (see AppAvatar).
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: clipped,
    );
  }

  ImageProvider? _resolveProvider() {
    if (imageProvider != null) return imageProvider;
    final url = (imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl
        : (categoryImageUrl != null && categoryImageUrl!.isNotEmpty)
            ? categoryImageUrl
            : null;
    if (url == null) return null;
    return NetworkImage(url);
  }

  static String _initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first;
  }

  /// Same stable, cross-run hash used by [AppAvatar].
  static int _stableHash(String s) {
    var h = 2166136261;
    for (final unit in s.codeUnits) {
      h = ((h ^ unit) * 16777619) & 0x7fffffff;
    }
    return h;
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.initial,
    required this.background,
    required this.foreground,
    required this.size,
  });

  final String initial;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: background,
      child: Text(
        initial,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
