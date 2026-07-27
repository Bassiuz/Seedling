/// A project label shown as a chip on a task.
///
/// [colorIndex] indexes `SeedlingPalette.tagColors` and [iconIndex] indexes the
/// app's fixed icon list rather than storing a colour value or an icon
/// codepoint. Both lists are therefore ordering contracts — reordering one
/// silently restyles every stored tag, so their order is pinned by a test.
/// Storing an index also keeps icons tree-shakeable in release builds, which a
/// dynamically built `IconData` would not be.
class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.iconIndex,
    required this.sortOrder,
  });

  factory Tag.fromMap(String id, Map<String, dynamic> map) => Tag(
        id: id,
        name: map['name'] as String? ?? '',
        colorIndex: map['colorIndex'] as int? ?? 0,
        iconIndex: map['iconIndex'] as int? ?? 0,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  final String id;
  final String name;
  final int colorIndex;
  final int iconIndex;
  final int sortOrder;

  Map<String, dynamic> toMap() => {
        'name': name,
        'colorIndex': colorIndex,
        'iconIndex': iconIndex,
        'sortOrder': sortOrder,
      };
}
