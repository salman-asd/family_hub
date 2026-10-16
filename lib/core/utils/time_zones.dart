import 'package:timezone/data/latest.dart' as tzdata;

/// Family timezone used until the family settings say otherwise.
const String defaultTimezone = 'Asia/Dhaka';

bool _initialized = false;

/// Loads the timezone database once. Safe to call repeatedly.
void ensureTimeZonesInitialized() {
  if (_initialized) {
    return;
  }
  tzdata.initializeTimeZones();
  _initialized = true;
}
