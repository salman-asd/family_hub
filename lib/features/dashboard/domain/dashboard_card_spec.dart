/// A catalog card's presentation builder, supplied by its owning module.
///
/// The generic keeps Flutter and Riverpod types out of the domain layer while
/// allowing the presentation layer to use a strongly typed builder.
final class DashboardCardSpec<TBuilder> {
  const DashboardCardSpec({required this.id, required this.builder});

  final String id;
  final TBuilder builder;
}
