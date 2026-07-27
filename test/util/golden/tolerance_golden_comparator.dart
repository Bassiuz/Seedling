import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class ToleranceGoldenComparator extends LocalFileComparator {
  ToleranceGoldenComparator(
    super.testFile, {
    required this.diffTolerance,
  });
  final double diffTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    // compares list of bytes
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    // check the the result or take into consideration the difference
    final bool passed = result.passed || result.diffPercent <= diffTolerance;

    // if we are within difference, we still want to pass the test
    // if we are not, we are throwing error
    if (!passed) {
      final String error = await generateFailureOutput(result, golden, basedir);
      result.dispose();
      throw FlutterError(error);
    }

    result.dispose();
    return passed;
  }
}
