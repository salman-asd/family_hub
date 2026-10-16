enum Flavor {
  dev,
  prod;

  String get label => this == Flavor.dev ? 'Family Hub (dev)' : 'Family Hub';
}
