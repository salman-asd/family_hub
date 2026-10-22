import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:flutter/foundation.dart';

/// Standard audit and schema metadata carried by all Firestore documents.
///
/// Follows CLAUDE.md Hard Rule 5:
/// "Soft delete only (deletedAt, deletedBy). Every document has createdAt,
/// createdBy, updatedAt, updatedBy, schemaVersion."
@immutable
class BaseDocumentMetadata {
  const BaseDocumentMetadata({
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.schemaVersion = 1,
    this.deletedAt,
    this.deletedBy,
  });

  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int schemaVersion;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  BaseDocumentMetadata copyWith({
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    int? schemaVersion,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return BaseDocumentMetadata(
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseDocumentMetadata &&
          other.createdAt == createdAt &&
          other.createdBy == createdBy &&
          other.updatedAt == updatedAt &&
          other.updatedBy == updatedBy &&
          other.schemaVersion == schemaVersion &&
          other.deletedAt == deletedAt &&
          other.deletedBy == deletedBy;

  @override
  int get hashCode => Object.hash(
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    schemaVersion,
    deletedAt,
    deletedBy,
  );

  @override
  String toString() =>
      'BaseDocumentMetadata('
      'createdAt: $createdAt, createdBy: $createdBy, '
      'updatedAt: $updatedAt, updatedBy: $updatedBy, '
      'schemaVersion: $schemaVersion, '
      'deletedAt: $deletedAt, deletedBy: $deletedBy)';
}

/// Helper methods for converting, creating, and updating standard metadata
/// fields across all data mappers.
abstract final class BaseMapper {
  static const String keyCreatedAt = 'createdAt';
  static const String keyCreatedBy = 'createdBy';
  static const String keyUpdatedAt = 'updatedAt';
  static const String keyUpdatedBy = 'updatedBy';
  static const String keySchemaVersion = 'schemaVersion';
  static const String keyDeletedAt = 'deletedAt';
  static const String keyDeletedBy = 'deletedBy';

  /// Deserializes standard metadata from a Firestore document map.
  static BaseDocumentMetadata metadataFromMap(Map<String, dynamic> map) {
    return BaseDocumentMetadata(
      createdAt:
          timestampToDateTime(map[keyCreatedAt]) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdBy: map[keyCreatedBy] as String? ?? '',
      updatedAt:
          timestampToDateTime(map[keyUpdatedAt]) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedBy: map[keyUpdatedBy] as String? ?? '',
      schemaVersion: (map[keySchemaVersion] as num?)?.toInt() ?? 1,
      deletedAt: timestampToDateTime(map[keyDeletedAt]),
      deletedBy: map[keyDeletedBy] as String?,
    );
  }

  /// Serializes standard metadata into Firestore map fields.
  static Map<String, dynamic> metadataToMap(BaseDocumentMetadata metadata) {
    return <String, dynamic>{
      keyCreatedAt: dateTimeToTimestamp(metadata.createdAt),
      keyCreatedBy: metadata.createdBy,
      keyUpdatedAt: dateTimeToTimestamp(metadata.updatedAt),
      keyUpdatedBy: metadata.updatedBy,
      keySchemaVersion: metadata.schemaVersion,
      keyDeletedAt: dateTimeToTimestamp(metadata.deletedAt),
      keyDeletedBy: metadata.deletedBy,
    };
  }

  /// Creates initial metadata for a newly created document.
  static BaseDocumentMetadata createMetadata({
    required String uid,
    required Clock clock,
    int schemaVersion = 1,
  }) {
    final now = clock.nowUtc();
    return BaseDocumentMetadata(
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      schemaVersion: schemaVersion,
    );
  }

  /// Updates metadata for a modified document.
  static BaseDocumentMetadata updateMetadata(
    BaseDocumentMetadata current, {
    required String uid,
    required Clock clock,
  }) {
    return current.copyWith(updatedAt: clock.nowUtc(), updatedBy: uid);
  }

  /// Soft deletes a document by recording [deletedAt] and [deletedBy].
  static BaseDocumentMetadata softDeleteMetadata(
    BaseDocumentMetadata current, {
    required String uid,
    required Clock clock,
  }) {
    final now = clock.nowUtc();
    return current.copyWith(
      updatedAt: now,
      updatedBy: uid,
      deletedAt: now,
      deletedBy: uid,
    );
  }

  /// Safely converts a Firestore [Timestamp], [DateTime], or ISO string into a UTC [DateTime].
  static DateTime? timestampToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toUtc();
    }
    return null;
  }

  /// Safely converts a [DateTime] into a Firestore [Timestamp].
  static Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime.toUtc());
  }
}
