import 'package:flutter/material.dart';

/// The Seedling color tokens (design doc: "E-ink mode & the Seedling palette").
///
/// The accents are exactly the colors the BigMe B7 e-ink panel can display,
/// authored fully saturated because the panel desaturates them itself. One set
/// of colors for iPhone, Mac and e-ink — no per-mode mapping.
class SeedlingPalette {
  const SeedlingPalette._();

  // Neutrals.
  static const Color ink = Color(0xFF000000);
  static const Color grayDark = Color(0xFF555555);
  static const Color gray = Color(0xFF888888);
  static const Color grayLight = Color(0xFFC4C4C4);

  // Accents.
  static const Color red = Color(0xFFFF0022);
  static const Color green = Color(0xFF00CC44);
  static const Color blue = Color(0xFF1122DD);
  static const Color cyan = Color(0xFF00DDDD);
  static const Color orange = Color(0xFFFF9900);
  static const Color yellow = Color(0xFFFFEE00);
  static const Color greenDeep = Color(0xFF2E8B57);
  static const Color purple = Color(0xFF7B2FBE);
  static const Color azure = Color(0xFF1E90FF);
  static const Color crimson = Color(0xFFD81B60);
  static const Color magenta = Color(0xFFFF00CC);

  // Paper (the warm notebook surface and its ruled lines).
  static const Color paper = Color(0xFFF9F5EC);
  static const Color paperLine = Color(0xFFE8E0CE);

  /// Colors a tag can be, indexed by `Tag.colorIndex`. Order is stable:
  /// changing it would repaint every existing tag.
  static const List<Color> tagColors = [
    red,
    green,
    blue,
    cyan,
    orange,
    yellow,
    greenDeep,
    purple,
    azure,
    crimson,
    magenta,
  ];
}
