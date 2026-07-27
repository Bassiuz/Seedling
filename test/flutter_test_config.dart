import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'util/golden/load_fonts.dart';
import 'util/golden/tolerance_golden_comparator.dart';

const _kGoldenTestsThreshold = 0.0;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final testUrl = (goldenFileComparator as LocalFileComparator).basedir;

    await loadFonts();

    goldenFileComparator = ToleranceGoldenComparator(
      Uri.parse('$testUrl/test.dart'),
      diffTolerance: _kGoldenTestsThreshold,
    );
  } else {
    throw Exception(
      'Expected goldenFileComparator to be of type '
      'LocalFileComparator '
      'but it is of type ${goldenFileComparator.runtimeType}',
    );
  }
  await testMain();
}
