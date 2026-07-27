import 'package:flutter/material.dart';

/// The icons a tag can use. `Tag.iconIndex` indexes this list, so — like
/// `SeedlingPalette.tagColors` — its order is a persistence contract:
/// reordering it silently re-icons every stored tag. Append, never insert.
///
/// A fixed const list also keeps Flutter's icon tree-shaking working, which a
/// dynamically constructed `IconData` would break.
const List<IconData> tagIcons = [
  Icons.circle_outlined,
  Icons.code,
  Icons.phone_iphone,
  Icons.directions_bike,
  Icons.home_outlined,
  Icons.favorite_outline,
  Icons.shopping_cart_outlined,
  Icons.school_outlined,
  Icons.videocam_outlined,
  Icons.music_note_outlined,
  Icons.pets,
  Icons.star_outline,
];
