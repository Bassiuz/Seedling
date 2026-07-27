import 'package:flutter/material.dart';

import 'golden_utils.dart';

/// Smoke test for the golden infrastructure itself: config, comparator,
/// fonts, and size helpers. If this breaks, all golden tests are suspect.
void main() {
  goldenForSizes(
    'golden infra smoke',
    'infra_smoke',
    [GoldenSize.phone],
    () => const Scaffold(
      body: Center(child: Text('golden infra')),
    ),
  );
}
