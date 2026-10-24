import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/level.dart';
import 'painters.dart';
import 'palette.dart';

class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool secondary;
  final Widget? trailing;

  const BigButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.secondary = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: secondary ? Colors.white : Palette.accent,
      foregroundColor: secondary ? Palette.ink : Colors.white,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      elevation: secondary ? 0 : 2,
      side: secondary
          ? BorderSide(color: Palette.cardboard.withValues(alpha: 0.5))
          : null,
    );
    return FilledButton(
      style: style,
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class HintButton extends StatelessWidget {
  final int count;
  final VoidCallback? onPressed;

  const HintButton({super.key, required this.count, this.onPressed});

  @override
  Widget build(BuildContext context) => Badge(
    label: Text(count > 0 ? '$count' : '+'),
    backgroundColor: count > 0 ? Palette.accent : Palette.good,
    child: IconButton.filledTonal(
      tooltip: 'Hint',
      onPressed: onPressed,
      icon: const Icon(Icons.lightbulb_rounded),
      color: Palette.ink,
    ),
  );
}

class RuleChip extends StatelessWidget {
  final String text;

  const RuleChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Palette.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// The logo art: a happy cat peeking out of a box.
class CatInBox extends StatelessWidget {
  final double size;
  final int fur;

  const CatInBox({super.key, required this.size, this.fur = 0});

  @override
  Widget build(BuildContext context) {
    final boxShape = Shape(const [(0, 0), (0, 1)]);
    final cell = size / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: size * 0.05,
            top: 0,
            child: CustomPaint(
              size: Size(size * 0.9, size * 0.9),
              painter: CatPainter(
                fur: fur,
                trait: CatTrait.chonk,
                mood: CatMood.happy,
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: CustomPaint(
              size: Size(size, cell),
              painter: CardboardPainter(boxShape, cell),
            ),
          ),
        ],
      ),
    );
  }
}
