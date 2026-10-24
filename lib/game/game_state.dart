import 'package:flutter/foundation.dart';

import 'level.dart';

class Placement {
  final int turns;
  final Cell origin;
  const Placement(this.turns, this.origin);
}

enum CatMood {
  /// Not inside any box yet.
  waiting,

  /// Alone in a box it likes.
  happy,

  /// Sharing a box with another cat.
  crowded,

  /// In a box of the wrong size for its trait.
  picky,
}

/// Mutable play state for one level: where each box is and how it's turned.
class GameState extends ChangeNotifier {
  final Level level;

  /// Rotation of every piece, whether it's in the tray or on the board.
  final List<int> turns;
  final Map<int, Placement> placed = {};

  /// Pieces placed by a hint; they can't be moved.
  final Set<int> locked = {};

  int moves = 0;

  GameState(this.level) : turns = List.filled(level.pieces.length, 0);

  Shape shapeOf(int piece, [int? t]) =>
      level.pieces[piece].shape.rotatedBy(t ?? turns[piece]);

  List<Cell> cellsOfPlaced(int piece) {
    final p = placed[piece]!;
    return cellsAt(shapeOf(piece, p.turns), p.origin);
  }

  /// Which piece covers each board cell.
  Map<Cell, int> get occupancy => {
    for (final i in placed.keys)
      for (final c in cellsOfPlaced(i)) c: i,
  };

  bool canPlace(int piece, int t, Cell origin) {
    final occ = occupancy;
    for (final c in cellsAt(shapeOf(piece, t), origin)) {
      if (!level.inBounds(c) || level.furniture.contains(c)) return false;
      final o = occ[c];
      if (o != null && o != piece) return false;
    }
    return true;
  }

  /// Puts [piece] at [origin] if it fits. Returns whether it moved.
  bool place(int piece, Cell origin) {
    if (locked.contains(piece)) return false;
    final t = turns[piece];
    if (!canPlace(piece, t, origin)) return false;
    final prev = placed[piece];
    if (prev != null && prev.origin == origin && prev.turns == t) return false;
    placed[piece] = Placement(t, origin);
    moves++;
    notifyListeners();
    return true;
  }

  void returnToTray(int piece) {
    if (locked.contains(piece) || placed.remove(piece) == null) return;
    moves++;
    notifyListeners();
  }

  /// Rotates a piece clockwise. A piece on the board is turned in place,
  /// nudged to the nearest spot that fits, or sent back to the tray.
  void rotate(int piece) {
    if (locked.contains(piece)) return;
    final t = (turns[piece] + 1) % 4;
    turns[piece] = t;
    final p = placed[piece];
    if (p != null) {
      final old = shapeOf(piece, p.turns);
      final now = shapeOf(piece, t);
      // Keep the box centred where it was.
      final base = (
        p.origin.$1 + (old.rows - now.rows) ~/ 2,
        p.origin.$2 + (old.cols - now.cols) ~/ 2,
      );
      Cell? spot;
      search:
      for (var dist = 0; dist <= 1; dist++) {
        for (var dr = -dist; dr <= dist; dr++) {
          for (var dc = -dist; dc <= dist; dc++) {
            final o = (base.$1 + dr, base.$2 + dc);
            if (canPlace(piece, t, o)) {
              spot = o;
              break search;
            }
          }
        }
      }
      if (spot != null) {
        placed[piece] = Placement(t, spot);
      } else {
        placed.remove(piece);
      }
    }
    moves++;
    notifyListeners();
  }

  CatMood moodOf(int catIndex) {
    final cat = level.cats[catIndex];
    final box = occupancy[cat.cell];
    if (box == null) return CatMood.waiting;
    final cells = cellsOfPlaced(box).toSet();
    final roommates = level.cats.where((c) => cells.contains(c.cell)).length;
    if (roommates > 1) return CatMood.crowded;
    if (!traitAccepts(cat.trait, cells.length)) return CatMood.picky;
    return CatMood.happy;
  }

  /// Solved when every box is out and every cat is happy. With one cat per
  /// box that means each box holds exactly one cat.
  bool get solved =>
      placed.length == level.pieces.length &&
      [for (var i = 0; i < level.cats.length; i++) moodOf(i)]
          .every((m) => m == CatMood.happy);

  /// Places one box where it belongs in the stored solution, clearing any
  /// boxes in the way. Returns false if there's nothing left to hint.
  bool hint() {
    for (var i = 0; i < level.pieces.length; i++) {
      if (locked.contains(i)) continue;
      final piece = level.pieces[i];
      final target = cellsAt(
        piece.shape.rotatedBy(piece.solutionTurns),
        piece.solutionOrigin,
      );
      final p = placed[i];
      if (p != null && cellsOfPlaced(i).toSet().containsAll(target)) continue;
      final occ = occupancy;
      for (final c in target) {
        final o = occ[c];
        if (o != null && o != i) placed.remove(o);
      }
      turns[i] = piece.solutionTurns;
      placed[i] = Placement(piece.solutionTurns, piece.solutionOrigin);
      locked.add(i);
      notifyListeners();
      return true;
    }
    return false;
  }

  void reset() {
    placed.removeWhere((k, _) => !locked.contains(k));
    moves = 0;
    notifyListeners();
  }
}
