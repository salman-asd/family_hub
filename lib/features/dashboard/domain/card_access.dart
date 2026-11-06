enum CardAccess {
  hidden,
  on,
  off,
  required;

  static CardAccess parse(String? value, {required CardAccess fallback}) =>
      CardAccess.values.firstWhere(
        (access) => access.name == value,
        orElse: () => fallback,
      );
}
