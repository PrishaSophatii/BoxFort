import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_state.dart';
import '../game/level.dart';
import 'painters.dart';
import 'palette.dart';

class DragData {
  final int piece;
  final bool fromBoard;
  const DragData(this.piece, {required this.fromBoard});
}

/// Neighbouring boxes get slightly different cardboard so they read apart.
const _cardboardShades = [
  Palette.cardboard,
  Color(0xFFBF8A52),
  Color(0xFFD09E66),
  Color(0xFFC49060),
];

Widget boxView(
  Shape shape,
  double cell, {
  bool locked = false,
  int shade = 0,
}) => CustomPaint(
  size: Size(shape.cols * cell, shape.rows * cell),
  painter: CardboardPainter(
    shape,
    cell,
    locked: locked,
    tint: _cardboardShades[shade % _cardboardShades.length],
  ),
);

/// The room where boxes are dropped.
class Board extends StatefulWidget {
  final GameState game;
  final double cell;

  const Board({super.key, required this.game, required this.cell});

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  final _key = GlobalKey();
  (int, Cell)? _preview;

  GameState get game => widget.game;
  double get cell => widget.cell;

  Cell _originFor(Offset globalTopLeft) {
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalTopLeft);
    return ((local.dy / cell).round(), (local.dx / cell).round());
  }

  @override
  Widget build(BuildContext context) {
    final level = game.level;
    final occ = game.occupancy;
    return DragTarget<DragData>(
      onMove: (d) {
        final next = (d.data.piece, _originFor(d.offset));
        if (next != _preview) setState(() => _preview = next);
      },
      onLeave: (_) => setState(() => _preview = null),
      onAcceptWithDetails: (d) {
        setState(() => _preview = null);
        if (game.place(d.data.piece, _originFor(d.offset))) {
          HapticFeedback.lightImpact();
        }
      },
      builder: (context, _, _) => SizedBox(
        key: _key,
        width: level.cols * cell,
        height: level.rows * cell,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: FloorPainter(level, cell)),
            ),
            for (final entry in game.placed.entries)
              Positioned(
                left: entry.value.origin.$2 * cell,
                top: entry.value.origin.$1 * cell,
                child: _placedBox(entry.key, entry.value),
              ),
            if (_preview != null) _ghost(_preview!.$1, _preview!.$2),
            for (var i = 0; i < level.cats.length; i++)
              Positioned(
                left: level.cats[i].cell.$2 * cell,
                top: level.cats[i].cell.$1 * cell,
                child: IgnorePointer(
                  child: CatTile(
                    cat: level.cats[i],
                    mood: game.moodOf(i),
                    size: cell,
                    boxed: occ.containsKey(level.cats[i].cell),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placedBox(int piece, Placement p) {
    final shape = game.shapeOf(piece, p.turns);
    final view = boxView(
      shape,
      cell,
      locked: game.locked.contains(piece),
      shade: piece,
    );
    if (game.locked.contains(piece)) return view;
    return Draggable<DragData>(
      data: DragData(piece, fromBoard: true),
      feedback: Opacity(
        opacity: 0.85,
        child: boxView(shape, cell, shade: piece),
      ),
      childWhenDragging: const SizedBox.shrink(),
      onDraggableCanceled: (_, _) => game.returnToTray(piece),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          game.rotate(piece);
        },
        child: view,
      ),
    );
  }

  Widget _ghost(int piece, Cell origin) {
    final shape = game.shapeOf(piece);
    final ok = game.canPlace(piece, game.turns[piece], origin);
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GhostPainter(
            cellsAt(shape, origin),
            cell,
            ok ? Palette.good : Palette.bad,
          ),
        ),
      ),
    );
  }
}

class _GhostPainter extends CustomPainter {
  final List<Cell> cells;
  final double cell;
  final Color color;

  _GhostPainter(this.cells, this.cell, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color.withValues(alpha: 0.35);
    for (final (r, c) in cells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cell, r * cell, cell, cell).deflate(2),
          Radius.circular(cell * 0.15),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_GhostPainter old) => true;
}

/// A cat with its mood bubble and size badge.
class CatTile extends StatelessWidget {
  final Cat cat;
  final CatMood mood;
  final double size;
  final bool boxed;

  const CatTile({
    super.key,
    required this.cat,
    required this.mood,
    required this.size,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge = switch (cat.trait) {
      CatTrait.kitten => '≤$kittenMaxBox',
      CatTrait.chonk => '$chonkMinBox+',
      CatTrait.none => null,
    };
    final bubble = switch (mood) {
      CatMood.crowded => ('!', Palette.bad),
      CatMood.picky => ('?', Palette.inkSoft),
      _ => null,
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedScale(
              scale: mood == CatMood.happy ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: CustomPaint(
                painter: CatPainter(fur: cat.fur, trait: cat.trait, mood: mood),
              ),
            ),
          ),
          if (mood == CatMood.happy)
            Positioned(
              right: size * 0.02,
              top: -size * 0.05,
              child: Text(
                'z',
                style: TextStyle(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w800,
                  color: Palette.ink.withValues(alpha: 0.6),
                ),
              ),
            ),
          if (badge != null)
            Positioned(
              left: size * 0.04,
              bottom: size * 0.04,
              child: _Pill(badge, Palette.ink, size * 0.2),
            ),
          if (bubble != null)
            Positioned(
              right: 0,
              top: 0,
              child: _Pill(bubble.$1, bubble.$2, size * 0.24),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const _Pill(this.text, this.color, this.fontSize);

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: fontSize * 0.3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(fontSize),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    ),
  );
}

/// The shelf of boxes waiting to be placed.
class Tray extends StatelessWidget {
  final GameState game;
  final double boardCell;

  const Tray({super.key, required this.game, required this.boardCell});

  @override
  Widget build(BuildContext context) {
    final waiting = [
      for (var i = 0; i < game.level.pieces.length; i++)
        if (!game.placed.containsKey(i)) i,
    ];
    final cell = (boardCell * 0.42).clamp(12.0, 24.0);
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (d) => d.data.fromBoard,
      onAcceptWithDetails: (d) => game.returnToTray(d.data.piece),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        constraints: BoxConstraints(minHeight: cell * 3 + 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? Palette.cardboardLight.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Palette.cardboard.withValues(alpha: 0.4)),
        ),
        child: waiting.isEmpty
            ? Center(
                child: Text(
                  game.solved ? 'Every cat is cozy!' : 'All boxes are out',
                  style: const TextStyle(
                    color: Palette.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [for (final i in waiting) _trayPiece(i, cell)],
              ),
      ),
    );
  }

  Widget _trayPiece(int piece, double cell) {
    final shape = game.shapeOf(piece);
    final w = shape.cols * boardCell, h = shape.rows * boardCell;
    return Draggable<DragData>(
      data: DragData(piece, fromBoard: false),
      // Hold the box a little above the finger so it stays visible.
      dragAnchorStrategy: (_, _, _) => Offset(w / 2, h / 2 + boardCell * 0.9),
      feedback: Opacity(
        opacity: 0.9,
        child: boxView(shape, boardCell, shade: piece),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: boxView(shape, cell, shade: piece),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          game.rotate(piece);
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(4),
          child: boxView(shape, cell, shade: piece),
        ),
      ),
    );
  }
}
