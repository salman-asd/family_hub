import 'package:family_hub/features/family/domain/module_flags.dart';

/// A family and its general settings.
class Family {
  const Family({
    required this.id,
    required this.name,
    this.timezone = defaultTimezone,
    this.currency = defaultCurrency,
    this.modules = ModuleFlags.allOn,
  });

  static const String defaultTimezone = 'Asia/Dhaka';
  static const String defaultCurrency = 'BDT';

  final String id;
  final String name;
  final String timezone;
  final String currency;
  final ModuleFlags modules;

  Family copyWith({
    String? name,
    String? timezone,
    String? currency,
    ModuleFlags? modules,
  }) => Family(
    id: id,
    name: name ?? this.name,
    timezone: timezone ?? this.timezone,
    currency: currency ?? this.currency,
    modules: modules ?? this.modules,
  );

  @override
  bool operator ==(Object other) =>
      other is Family &&
      other.id == id &&
      other.name == name &&
      other.timezone == timezone &&
      other.currency == currency &&
      other.modules == modules;

  @override
  int get hashCode => Object.hash(id, name, timezone, currency, modules);
}
