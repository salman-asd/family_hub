import 'package:family_hub/app/flavor.dart';
import 'package:flutter/material.dart';

/// Placeholder app shell (Step 1). Replaced by MaterialApp.router in Step 8.
class FamilyHubApp extends StatelessWidget {
  const FamilyHubApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: flavor.label,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text(flavor.label)),
        body: Center(
          child: Text(
            flavor.name,
            key: const Key('flavor_name'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
