import 'package:flutter/material.dart';

/// From this width the Month view is two panes: the grid and a permanent day
/// panel (B.2, P3-24). Tablets and large foldables; a phone in landscape uses
/// the Week or the Agenda instead.
const double kTwoPaneMinWidth = 840;

/// The tablet layout of the Month view: [grid] on the leading side, [panel]
/// (the selected day) beside it. Pure layout: no provider, no data.
///
/// The grid gets 3 parts of the width and the panel 2, so at 840 dp the grid
/// cells are still about 70 dp wide (>= 48) and the panel about 330 dp.
class CalendarTwoPane extends StatelessWidget {
  const CalendarTwoPane({required this.grid, required this.panel, super.key});

  final Widget grid;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: grid),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 12, 12),
            child: panel,
          ),
        ),
      ],
    );
  }
}
