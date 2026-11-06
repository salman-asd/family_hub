import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/notifications/domain/device_token.dart';

abstract final class DeviceTokenMappers {
  static const Set<String> keys = <String>{
    'token',
    'platform',
    'lang',
    'appVersion',
    'flavor',
    'lastSeenAt',
    'createdAt',
    'createdBy',
    'updatedAt',
    'updatedBy',
    'schemaVersion',
  };

  static Map<String, Object> toMap(
    String uid,
    DeviceTokenRegistration registration,
  ) => <String, Object>{
    'token': registration.token,
    'platform': 'android',
    'lang': registration.languageCode,
    'appVersion': registration.appVersion,
    'flavor': registration.flavor,
    'lastSeenAt': Timestamp.fromDate(registration.lastSeenAt.toUtc()),
    'createdAt': Timestamp.fromDate(registration.createdAt.toUtc()),
    'createdBy': uid,
    'updatedAt': Timestamp.fromDate(registration.lastSeenAt.toUtc()),
    'updatedBy': uid,
    'schemaVersion': 1,
  };
}
