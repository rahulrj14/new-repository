import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../catalog/stickers.dart';
import '../theme/tokens.dart';
import 'blob_avatar.dart';

/// A reaction sticker of your own blob with a chunky label.
class BlobSticker extends StatelessWidget {
  const BlobSticker({
    super.key,
    required this.sticker,
    required this.avatarId,
    required this.skinId,
    this.size = 120,
  });
  final Sticker sticker;
  final int avatarId;
  final int skinId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mood = switch (sticker.mood) {
      'sleepy' => BlobMood.sleepy,
      'shocked' => BlobMood.shocked,
      'happy' => BlobMood.happy,
      _ => BlobMood.idle,
    };
    return Semantics(
      label: '${sticker.label} sticker',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: BlobAvatar(
                avatarId: avatarId,
                skinId: skinId,
                size: size * 0.82,
                mood: mood,
                cracked: sticker.cracked,
                animate: false,
              ),
            ),
            Positioned(
              bottom: size * 0.02,
              child: Transform.rotate(
                angle: -6 * math.pi / 180,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size * 0.07,
                    vertical: size * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: sticker.cracked ? LockColors.coral : LockColors.sun,
                    borderRadius: BorderRadius.circular(size * 0.08),
                    border: Border.all(color: Colors.white, width: size * 0.03),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33111827),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    sticker.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: kFont,
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.105,
                      color: sticker.cracked ? Colors.white : LockColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
