import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// A chart plus the text alternative a screen reader announces.
///
/// Charts are decoration; the table beneath every chart is the real content,
/// so the chart itself is wrapped in ONE `Semantics(label:)` node with
/// `excludeSemantics` (rule 13: a status is announced once, and never by colour
/// alone).
class ReportChartCard extends StatelessWidget {
  const ReportChartCard({
    required this.title,
    required this.semanticsLabel,
    required this.child,
    this.height = 220,
    super.key,
  });

  final String title;

  /// Generated text alternative (e.g. "Vegetables ৳4,045, 34 % of total").
  final String semanticsLabel;

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: semanticsLabel,
            excludeSemantics: true,
            child: SizedBox(height: height, child: child),
          ),
        ],
      ),
    );
  }
}

/// Empty placeholder for a tab whose data has nothing to chart.
class ReportChartEmpty extends StatelessWidget {
  const ReportChartEmpty({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}


