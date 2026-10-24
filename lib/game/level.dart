import 'dart:math';

/// A grid position as (row, col).
typedef Cell = (int, int);

/// A polyomino: the cells a box covers, normalized so the top-left of its
/// bounding box is (0, 0).
class Shape {
  final List<Cell> cells;
  final int rows;
  final int cols;

  Shape._(this.cells, this.rows, this.cols);

  factory Shape(Iterable<Cell> raw) {
    final list = raw.toList();
    final minR = list.map((c) => c.$1).reduce(min);
    final minC = list.map((c) => c.$2).reduce(min);
    final norm = [for (final (r, c) in list) (r - minR, c - minC)]
      ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    final rows = norm.map((c) => c.$1).reduce(max) + 1;
    final cols = norm.map((c) => c.$2).reduce(max) + 1;
    return Shape._(List.unmodifiable(norm), rows, cols);
  }

  int get size => cells.length;

  /// Rotated 90 degrees clockwise.
  Shape rotated() => Shape([for (final (r, c) in cells) (c, -r)]);

  Shape rotatedBy(int turns) {
    var s = this;
    for (var i = 0; i < turns % 4; i++) {
      s = s.rotated();
    }
    return s;
  }

  bool contains(Cell cell) => cells.contains(cell);
}

enum CatTrait {
  /// Happy in any box.
  none,

  /// Only fits in a box of at most [kittenMaxBox] cells.
  kitten,

  /// Needs a roomy box of at least [chonkMinBox] cells.
  chonk,
}

const kittenMaxBox = 3;
const chonkMinBox = 5;

bool traitAccepts(CatTrait trait, int boxSize) => switch (trait) {
  CatTrait.none => true,
  CatTrait.kitten => boxSize <= kittenMaxBox,
  CatTrait.chonk => boxSize >= chonkMinBox,
};

class Cat {
  final Cell cell;
  final CatTrait trait;

  /// Index into the fur palette, purely cosmetic.
  final int fur;

  const Cat(this.cell, this.trait, this.fur);
}

class BoxPiece {
  /// The shape as it first appears in the tray.
  final Shape shape;

  /// Rotation (in clockwise turns from [shape]) and top-left cell of one
  /// known solution. Used for hints.
  final int solutionTurns;
  final Cell solutionOrigin;

  const BoxPiece(this.shape, this.solutionTurns, this.solutionOrigin);
}

class Level {
  final int rows;
  final int cols;
  final Set<Cell> furniture;
  final List<Cat> cats;
  final List<BoxPiece> pieces;

  const Level({
    required this.rows,
    required this.cols,
    required this.furniture,
    required this.cats,
    required this.pieces,
  });

  bool inBounds(Cell c) => c.$1 >= 0 && c.$1 < rows && c.$2 >= 0 && c.$2 < cols;
}

/// Cells covered by [shape] when its top-left sits at [origin].
List<Cell> cellsAt(Shape shape, Cell origin) => [
  for (final (r, c) in shape.cells) (r + origin.$1, c + origin.$2),
];
