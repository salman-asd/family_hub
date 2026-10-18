import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Debug-only screen at `/dev/gallery` (roadmap Step 11).
///
/// Renders every shared widget in every state, from [gallerySections] — the
/// same list the golden test walks — so the screen and the golden images can
/// never disagree about what "every state" means.
///
/// The route is registered only for the dev flavor, next to `/dev/tokens`.
class DevGalleryScreen extends StatelessWidget {
  const DevGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = gallerySections();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devGalleryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in sections) ...[
            SectionHeader(
              title: section.label(l10n),
              padding: const EdgeInsets.only(bottom: 12),
            ),
            section.build(context),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}
