import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/level.dart';
import 'palette.dart';

/// Draws a cardboard box covering [shape]'s cells. Edges are only drawn on
/// the outline so multi-cell boxes read as one box.
class CardboardPainter extends CustomPainter {
  final Shape shape;
  final double cell;
  final Color? tint;
  final bool locked;

  CardboardPainter(this.shape, this.cell, {this.tint, this.locked = false});

  @override
  void paint(Canvas canvas, Size size) {
    final inset = cell * 0.04;
    final fill = Paint()..color = tint ?? Palette.cardboard;
    final light = Paint()..color = Palette.cardboardLight;
    final edge = Paint()
      ..color = Palette.cardboardDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, cell * 0.05)
      ..strokeCap = StrokeCap.round;

    final set = shape.cells.toSet();
    for (final (r, c) in shape.cells) {
      final x = c * cell, y = r * cell;
      final left = !set.contains((r, c - 1));
      final right = !set.contains((r, c + 1));
      final top = !set.contains((r - 1, c));
      final bottom = !set.contains((r + 1, c));
      final rect = Rect.fromLTRB(
        x + (left ? inset : 0),
        y + (top ? inset : 0),
        x + cell - (right ? inset : 0),
        y + cell - (bottom ? inset : 0),
      );
      canvas.drawRect(rect, fill);
      // A lighter strip along the top edge reads as an open flap.
      if (top) {
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top, rect.width, cell * 0.14),
          light,
        );
      }
      if (left) canvas.drawLine(rect.topLeft, rect.bottomLeft, edge);
      if (right) canvas.drawLine(rect.topRight, rect.bottomRight, edge);
      if (top) canvas.drawLine(rect.topLeft, rect.topRight, edge);
      if (bottom) canvas.drawLine(rect.bottomLeft, rect.bottomRight, edge);
    }
    // Packing tape across the first row of the box.
    final (r0, c0) = shape.cells.first;
    final tape = Paint()..color = Palette.tape.withValues(alpha: 0.8);
    canvas.drawRect(
      Rect.fromLTWH(
        c0 * cell + cell * 0.42,
        r0 * cell + inset,
        cell * 0.16,
        cell * 0.6,
      ),
      tape,
    );
    if (locked) {
      final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
      for (final (r, c) in shape.cells) {
        canvas.drawCircle(
          Offset(c * cell + cell * 0.85, r * cell + cell * 0.85),
          cell * 0.06,
          p,
        );
      }
    }
  }

  @override
  bool? hitTest(Offset position) =>
      shape.contains((position.dy ~/ cell, position.dx ~/ cell));

  @override
  bool shouldRepaint(CardboardPainter old) =>
      old.shape != shape || old.cell != cell || old.tint != tint;
}

/// The room: floor tiles and furniture.
class FloorPainter extends CustomPainter {
  final Level level;
  final double cell;

  FloorPainter(this.level, this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(cell * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = Palette.floorA,
    );
    final b = Paint()..color = Palette.floorB;
    for (var r = 0; r < level.rows; r++) {
      for (var c = 0; c < level.cols; c++) {
        if ((r + c).isOdd) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), b);
        }
      }
    }
    final wall = Paint()..color = Palette.wall;
    final wallDark = Paint()..color = Palette.wallDark;
    for (final (r, c) in level.furniture) {
      final rect = Rect.fromLTWH(
        c * cell,
        r * cell,
        cell,
        cell,
      ).deflate(cell * 0.06);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.translate(0, cell * 0.04), radius),
        wallDark,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), wall);
      _drawFurnitureIcon(canvas, rect, (r * 31 + c * 17) % 3);
    }
  }

  void _drawFurnitureIcon(Canvas canvas, Rect rect, int kind) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final cx = rect.center.dx, cy = rect.center.dy, s = rect.width;
    switch (kind) {
      case 0: // potted plant
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy + s * 0.18),
            width: s * 0.3,
            height: s * 0.22,
          ),
          p,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx - s * 0.1, cy - s * 0.06),
            width: s * 0.2,
            height: s * 0.32,
          ),
          p,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + s * 0.1, cy - s * 0.1),
            width: s * 0.2,
            height: s * 0.32,
          ),
          p,
        );
      case 1: // stack of books
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(
                  cx + (i - 1) * s * 0.03,
                  cy + s * 0.16 - i * s * 0.14,
                ),
                width: s * 0.5,
                height: s * 0.1,
              ),
              Radius.circular(s * 0.02),
            ),
            p,
          );
        }
      default: // yarn ball
        canvas.drawCircle(Offset(cx, cy), s * 0.2, p);
        final line = Paint()
          ..color = Palette.wall
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: s * 0.13),
          -0.5,
          2.2,
          false,
          line,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx - s * 0.05, cy), radius: s * 0.2),
          -1,
          1.6,
          false,
          line,
        );
    }
  }

  @override
  bool shouldRepaint(FloorPainter old) =>
      old.level != level || old.cell != cell;
}

/// Draws a cat face.
class CatPainter extends CustomPainter {
  final int fur;
  final CatTrait trait;
  final CatMood mood;

  CatPainter({required this.fur, required this.trait, required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final (base, patch) = Palette.furs[fur % Palette.furs.length];
    final scale = switch (trait) {
      CatTrait.kitten => 0.7,
      CatTrait.chonk => 1.0,
      CatTrait.none => 0.86,
    };
    final s = size.width * scale;
    final cx = size.width / 2;
    final cy = size.height / 2 + size.height * 0.06;
    final wide = trait == CatTrait.chonk ? 1.18 : 1.0;
    final headW = s * 0.62 * wide, headH = s * 0.52;

    final outline = Paint()
      ..color = Palette.ink.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, s * 0.035)
      ..strokeJoin = StrokeJoin.round;
    final furPaint = Paint()..color = base;
    final patchPaint = Paint()..color = patch;

    // Ears.
    for (final side in [-1, 1]) {
      final ear = Path()
        ..moveTo(cx + side * headW * 0.42, cy - headH * 0.05)
        ..lineTo(cx + side * headW * 0.4, cy - headH * 0.78)
        ..lineTo(cx + side * headW * 0.06, cy - headH * 0.38)
        ..close();
      canvas.drawPath(ear, fur == 4 ? patchPaint : furPaint);
      canvas.drawPath(ear, outline);
    }

    final head = Rect.fromCenter(
      center: Offset(cx, cy),
      width: headW,
      height: headH,
    );
    canvas.drawOval(head, furPaint);
    if (fur == 5 || fur == 1) {
      canvas.save();
      canvas.clipPath(Path()..addOval(head));
      canvas.drawCircle(
        Offset(cx - headW * 0.3, cy - headH * 0.3),
        headW * 0.28,
        patchPaint,
      );
      canvas.restore();
    }
    if (fur == 4) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + headH * 0.12),
          width: headW * 0.5,
          height: headH * 0.42,
        ),
        patchPaint,
      );
    }
    canvas.drawOval(head, outline);

    final light = fur == 2;
    final eyeColor = light ? const Color(0xFFF5E27A) : Palette.ink;
    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.4, s * 0.04)
      ..strokeCap = StrokeCap.round;
    final ey = cy - headH * 0.05;
    final ex = headW * 0.2;

    switch (mood) {
      case CatMood.happy:
        // Sleepy closed eyes.
        for (final side in [-1, 1]) {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(cx + side * ex, ey),
              width: s * 0.12,
              height: s * 0.08,
            ),
            0.2,
            pi - 0.4,
            false,
            eyePaint,
          );
        }
      case CatMood.crowded:
        for (final side in [-1, 1]) {
          canvas.drawCircle(
            Offset(cx + side * ex, ey),
            s * 0.035,
            Paint()..color = eyeColor,
          );
          // Cross eyebrows.
          canvas.drawLine(
            Offset(cx + side * ex * 1.5, ey - s * 0.1),
            Offset(cx + side * ex * 0.5, ey - s * 0.06),
            eyePaint,
          );
        }
      case CatMood.picky:
      case CatMood.waiting:
        for (final side in [-1, 1]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx + side * ex, ey),
              width: s * 0.08,
              height: s * 0.11,
            ),
            Paint()..color = eyeColor,
          );
          canvas.drawCircle(
            Offset(cx + side * ex + s * 0.012, ey - s * 0.02),
            s * 0.014,
            Paint()..color = Colors.white,
          );
        }
    }

    // Nose and mouth.
    final ny = cy + headH * 0.12;
    final nose = Path()
      ..moveTo(cx - s * 0.035, ny)
      ..lineTo(cx + s * 0.035, ny)
      ..lineTo(cx, ny + s * 0.035)
      ..close();
    canvas.drawPath(nose, Paint()..color = const Color(0xFFE88A9A));
    final mouth = Paint()
      ..color = Palette.ink.withValues(alpha: light ? 0.9 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, s * 0.025)
      ..strokeCap = StrokeCap.round;
    if (mood == CatMood.crowded) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, ny + s * 0.09),
          width: s * 0.1,
          height: s * 0.06,
        ),
        pi + 0.3,
        pi - 0.6,
        false,
        mouth,
      );
    } else {
      for (final side in [-1, 1]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + side * s * 0.035, ny + s * 0.045),
            width: s * 0.07,
            height: s * 0.05,
          ),
          0,
          pi,
          false,
          mouth,
        );
      }
    }
    // Whiskers.
    for (final side in [-1, 1]) {
      for (final dy in [-0.02, 0.03]) {
        canvas.drawLine(
          Offset(cx + side * headW * 0.22, ny + s * dy),
          Offset(cx + side * headW * 0.56, ny + s * (dy * 2.2)),
          mouth,
        );
      }
    }

    if (trait == CatTrait.kitten) {
      // A little bow so kittens are easy to spot.
      final bow = Paint()..color = const Color(0xFFEF6F8E);
      final bx = cx + headW * 0.32, by = cy - headH * 0.42;
      canvas.drawCircle(Offset(bx - s * 0.05, by), s * 0.05, bow);
      canvas.drawCircle(Offset(bx + s * 0.05, by), s * 0.05, bow);
      canvas.drawCircle(
        Offset(bx, by),
        s * 0.03,
        Paint()..color = Palette.accentDark,
      );
    }
  }

  @override
  bool shouldRepaint(CatPainter old) =>
      old.fur != fur || old.trait != trait || old.mood != mood;
}
