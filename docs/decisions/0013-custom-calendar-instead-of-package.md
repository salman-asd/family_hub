# 0013 - Custom calendar instead of a calendar package (decision D-P3-16)

**Status:** accepted (Phase 3, P3-01).

**Context.** The chore calendar is the hero screen: Month, Week and Agenda,
Bangla names and digits, any week start, token-driven themes, 48 dp targets,
status glyphs, reduced motion. Packages such as `table_calendar`,
`calendar_view`, `kalender` or `syncfusion_*` each fight at least one of
these (theming through tokens, Bangla digits, week start, marker shapes).

**Decision.** Build the Month grid, Week strip and Agenda from small widgets
over a pure `CalendarMonthModel` (testable without Flutter, built on
`MonthMatrix`). Add only `animations` and `flutter_slidable` (D-P3-15).
`table_calendar` is the documented fallback ONLY if the custom month grid fails
the Appendix B acceptance checks (B.10).

**Consequences.** More code, fully ours, fully tested. The grid needs cells of
at least 48 dp: below about 336 dp screen width the Month view falls back to
the Week view automatically (D-P3-24).
