import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/notifications/data/notification_channels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('channel ids and names are localized in Bangla and English', () {
    final bangla = notificationChannels(
      lookupAppLocalizations(const Locale('bn')),
    );
    final english = notificationChannels(
      lookupAppLocalizations(const Locale('en')),
    );

    expect(
      bangla.map((channel) => channel.id.id).toList(),
      english.map((channel) => channel.id.id).toList(),
    );
    expect(
      bangla.map((channel) => channel.name).toList(),
      isNot(english.map((channel) => channel.name).toList()),
    );
    expect(bangla.every((channel) => channel.description.isNotEmpty), isTrue);
    expect(english.every((channel) => channel.description.isNotEmpty), isTrue);
  });
}
