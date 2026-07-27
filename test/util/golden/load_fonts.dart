import 'dart:io' as io; // Alias dart:io to avoid conflicts

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real fonts into the test font registry so goldens render actual
/// glyphs instead of the Ahem placeholder boxes.
Future<void> loadFonts() async {
  // FontLoader needs a live binding; without this the fonts are silently
  // not registered and goldens render placeholder boxes.
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1. Material Icons
  await _loadFontFamily('MaterialIcons', [
    'test/assets/fonts/MaterialIcons-Regular.otf',
  ]);

  // 2. Roboto (Material default / fallback text)
  await _loadFontFamily('Roboto', [
    'test/assets/fonts/Roboto-Regular.ttf',
  ]);

  // 3. SourceSans3 (app body/UI font)
  await _loadFontFamily('SourceSans3', [
    'test/assets/fonts/SourceSans3-Regular.ttf',
    'test/assets/fonts/SourceSans3-Medium.ttf',
    'test/assets/fonts/SourceSans3-SemiBold.ttf',
    'test/assets/fonts/SourceSans3-Bold.ttf',
  ]);

  // 4. SourceSerif4 (app headline font)
  await _loadFontFamily('SourceSerif4', [
    'test/assets/fonts/SourceSerif4-SemiBold.ttf',
    'test/assets/fonts/SourceSerif4-SemiBoldItalic.ttf',
  ]);

  // 5. Noto Color Emoji (emojis)
  await _loadFontFamily('NotoColorEmoji', [
    'test/assets/fonts/NotoColorEmoji-Regular.ttf',
  ]);
}

/// Every font load goes through here, so a font that silently disappears
/// (renamed, moved, dropped from a rebase) fails loudly instead of quietly
/// turning every golden into tofu boxes.
Future<void> _loadFontFamily(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = io.File(path).absolute;
    if (!file.existsSync()) {
      throw StateError(
        'Missing font file for family "$family": ${file.path}. '
        'Golden tests need it; restore it or fix the path in load_fonts.dart.',
      );
    }
    final bytes = await file.readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}
