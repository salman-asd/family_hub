# Local reminder device checklist

Use an Android phone with a signed or debug build. Keep the family timezone at
Asia/Dhaka unless the test says otherwise. Do not request notification or exact
alarm access during first launch; use the notification settings flow.

1. Enable notifications from the in-app settings explanation. Confirm a denied
   Android 13+ request is reported and can be retried from settings.
2. Enable exact alarms from the in-app explanation on Android 12 and Android
   14+. If access is denied, verify reminders are still scheduled inexactly and
   the UI reports that exact timing is unavailable.
3. Configure one chore reminder for two minutes from now. Close the app with
   the app switcher and confirm one notification appears with the small
   monochrome Family Hub icon. Tap it and confirm the chore opens.
4. Disable reminders for that template only. Confirm its scheduled reminder is
   cancelled while another template's reminder remains.
5. Enable battery saver and repeat the two-minute reminder. Record the device
   model and whether its battery-management settings delayed the notification.
6. Reboot after scheduling a reminder. Confirm the scheduled notification is
   restored and fires once.
7. Change the device timezone, resume the app, and confirm the reminder still
   fires at its configured instant. Change the timezone back and repeat.
8. Repeat on Android 12, Android 13, and Android 14 or newer. On Android 13+,
   test both notification permission denied and granted; on Android 14+, test
   exact alarm access denied and granted.
9. Repeat on two phone brands with aggressive battery management and record
   each result.
10. Disable the Bazar module and tap a Bazar reminder; it should open `/home`.
    Repeat with Chores disabled and a chore reminder.

Exact alarms use the user-granted `SCHEDULE_EXACT_ALARM` special access. Before
store release, verify that this app's reminder use meets the current Google
Play and Android exact-alarm policies. The app does not declare
`USE_EXACT_ALARM`; when exact access is unavailable, it schedules inexactly.

## Results

**Not run — 2026-11-07.** No Android device was attached to the machine that
finished Wave E, so every row above is still an open `[ ]`. The automated side
of these behaviours is covered (`flutter test --exclude-tags golden`, and the
two-phone reminder-plan tests in
`test/features/notifications/concurrency/two_phone_reminder_plan_test.dart`),
which is not evidence about a real notification drawer, battery manager or
reboot.

To close this file, record for each numbered step: device model, Android
version, app flavor/build, result, and a screenshot path — on **two brands**,
at least one with an aggressive battery manager. Steps 5, 6, 7 and 8 are the
ones a test cannot stand in for.
