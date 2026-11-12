import 'dart:ui';

/// Body silhouettes for the blob characters.
enum BlobShape { round, squircle, ghost, bean }

/// Little extras on top of the head.
enum BlobTopper { none, antenna, ears, horns, sprout, flame }

class AvatarSpec {
  const AvatarSpec(this.id, this.name, this.color, this.shape, this.topper);
  final int id;
  final String name;
  final Color color;
  final BlobShape shape;
  final BlobTopper topper;
}

/// Original Lock In characters. IDs are stable: they are stored and (later)
/// sent between phones, so never reorder; only append.
const avatars = <AvatarSpec>[
  AvatarSpec(0, 'Blip', Color(0xFFC8FF2E), BlobShape.round, BlobTopper.antenna),
  AvatarSpec(
    1,
    'Mochi',
    Color(0xFFFF7EB6),
    BlobShape.squircle,
    BlobTopper.ears,
  ),
  AvatarSpec(2, 'Boo', Color(0xFFB9A6FF), BlobShape.ghost, BlobTopper.none),
  AvatarSpec(3, 'Bean', Color(0xFF5CE1E6), BlobShape.bean, BlobTopper.sprout),
  AvatarSpec(4, 'Ember', Color(0xFFFF8A3D), BlobShape.round, BlobTopper.flame),
  AvatarSpec(
    5,
    'Gremlo',
    Color(0xFF3DFFA8),
    BlobShape.squircle,
    BlobTopper.horns,
  ),
  AvatarSpec(6, 'Sunny', Color(0xFFFFE14D), BlobShape.bean, BlobTopper.antenna),
  AvatarSpec(7, 'Nyx', Color(0xFF6E8BFF), BlobShape.ghost, BlobTopper.ears),
];

AvatarSpec avatarById(int id) => avatars[id.clamp(0, avatars.length - 1)];
