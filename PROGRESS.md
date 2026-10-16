# Family Hub - progress

| Step | Status | Notes |
| --- | --- | --- |
| 1 Scaffold, flavors, lints, CI | Done (found in repo) | android/ folder, flavors, analysis_options, CI, placeholder app, tools/setup.sh |
| 2 Core value objects | Done | flutter test 82/82 passes (includes Step 3 tests) |
| 3 Theme tokens | Done | app_tokens, modern_light, modern_dark, theme_registry, theme_builder, dev_tokens_screen; WCAG contrast + no-raw-color tests pass |
| 4 Theme controller and Settings → Theme screen | Next | |

## Step 2 assumptions
- Money.parse, Quantity.parse, DateKey.parse and MonthKey.parse return Result (no exceptions).
- Money formatting: bn uses lakh grouping (১২,৩৪,৫৬৭), en uses international grouping. Change in MoneyFormatter._group if unwanted.
- No freezed in core value objects (plain Dart), so no build_runner is needed for Step 2.
- DateKey.fromInstant loads the timezone database lazily (ensureTimeZonesInitialized).
- Unit enum has no ml; add later if a bazar item needs it.

## Step 3 assumptions
- Light theme accent changed from teal 600 (#00897B) to teal 800 (#00574B) so white text on accent meets WCAG AA 4.5:1.
- Light statusInProgressOn changed to #6A1900 (very dark) so it meets 4.5:1 on the peach container #FFE0B2.
- Dark theme textOnAccent changed to #00201C (very dark teal) because teal 300 accent is too light for white text.
- theme_builder.dart has two unavoidable Color() literals in SnackBar for the inverted fg/bg (they are inside lib/app/theme/ so the no-raw-color test allows them).
- The /dev/tokens route is intentionally left in until Step 4/8 replaces app.dart; it is debug-only and gated by the dev flavor in practice.
