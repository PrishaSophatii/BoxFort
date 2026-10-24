import 'dart:math';

import 'level.dart';
import 'rng.dart';

/// Knobs that set how hard a generated level is.
class Difficulty {
  final int size;
  final double furniture; // fraction of cells that are furniture
  final double coverage; // fraction of free floor the boxes fill
  final int minBox;
  final int maxBox;
  final double traitChance;
  final int maxPieces;

  const Difficulty({
    required this.size,
    required this.furniture,
    required this.coverage,
    required this.minBox,
    required this.maxBox,
    required this.traitChance,
    required this.maxPieces,
  });

  /// The difficulty curve for campaign level [n] (1-based).
  factory Difficulty.forLevel(int n) {
    final size = n <= 8
        ? 5
        : n <= 25
        ? 6
        : n <= 60
        ? 7
        : 8;
    return Difficulty(
      size: size,
      furniture: min(0.12 + n * 0.004, 0.3),
      coverage: min(0.3 + n * 0.06, 1.0),
      minBox: 2,
      maxBox: n <= 4
          ? 3
          : n <= 15
          ? 4
          : 5,
      traitChance: n < 6
          ? 0
          : n < 20
          ? 0.25
          : 0.4,
      maxPieces: min(2 + n ~/ 2, 12),
    );
  }

  /// Daily puzzles are a solid mid-game challenge.
  static const daily = Difficulty(
    size: 7,
    furniture: 0.24,
    coverage: 1.0,
    minBox: 2,
    maxBox: 5,
    traitChance: 0.35,
    maxPieces: 12,
  );
}

const furPalette = 6;

Level generateCampaignLevel(int n) =>
    generateLevel(Difficulty.forLevel(n), n * 7919 + 17);

Level generateDailyLevel(DateTime day) => generateLevel(
  Difficulty.daily,
  day.year * 10000 + day.month * 100 + day.day,
);

/// Builds a level by first carving a solution (boxes laid out on the floor,
/// one cat per box) and then taking the boxes away. That guarantees every
/// level is solvable.
Level generateLevel(Difficulty d, int seed) {
  for (var attempt = 0; attempt < 1000; attempt++) {
    final level = _tryGenerate(d, Rng(seed + attempt * 104729));
    if (level != null) return level;
  }
  throw StateError('could not generate a level for seed $seed');
}

const _dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

Level? _tryGenerate(Difficulty d, Rng rng) {
  final n = d.size;
  final all = [
    for (var r = 0; r < n; r++)
      for (var c = 0; c < n; c++) (r, c),
  ];
  bool inside(Cell c) => c.$1 >= 0 && c.$1 < n && c.$2 >= 0 && c.$2 < n;

  final furniture = <Cell>{};
  final shuffled = [...all];
  rng.shuffle(shuffled);
  furniture.addAll(shuffled.take((all.length * d.furniture).round()));

  // Partition the free floor into box-sized regions.
  final owner = <Cell, int>{};
  final regions = <List<Cell>>[];
  List<Cell> freeNeighbors(Cell c) => [
    for (final (dr, dc) in _dirs)
      if (inside((c.$1 + dr, c.$2 + dc)) &&
          !furniture.contains((c.$1 + dr, c.$2 + dc)) &&
          !owner.containsKey((c.$1 + dr, c.$2 + dc)))
        (c.$1 + dr, c.$2 + dc),
  ];

  while (true) {
    final open = [
      for (final c in all)
        if (!furniture.contains(c) && !owner.containsKey(c)) c,
    ];
    if (open.isEmpty) break;
    // Seed from the most cramped cell so we leave fewer stranded singletons.
    open.sort((a, b) => freeNeighbors(a).length - freeNeighbors(b).length);
    final fewest = freeNeighbors(open.first).length;
    final seed = rng.pick(
      open.where((c) => freeNeighbors(c).length == fewest).toList(),
    );
    final target = d.minBox + rng.nextInt(d.maxBox - d.minBox + 1);
    final id = regions.length;
    final region = [seed];
    owner[seed] = id;
    while (region.length < target) {
      final frontier = {for (final c in region) ...freeNeighbors(c)}.toList()
        ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
      if (frontier.isEmpty) break;
      final next = rng.pick(frontier);
      owner[next] = id;
      region.add(next);
    }
    regions.add(region);
  }

  // Fold regions that came out too small into a neighbour, or turn them
  // into furniture.
  for (var i = 0; i < regions.length; i++) {
    final region = regions[i];
    if (region.isEmpty || region.length >= d.minBox) continue;
    int? best;
    for (final c in region) {
      for (final (dr, dc) in _dirs) {
        final o = owner[(c.$1 + dr, c.$2 + dc)];
        if (o != null &&
            o != i &&
            regions[o].length + region.length <= d.maxBox &&
            (best == null || regions[o].length < regions[best].length)) {
          best = o;
        }
      }
    }
    if (best != null) {
      for (final c in region) {
        owner[c] = best;
      }
      regions[best].addAll(region);
    } else {
      for (final c in region) {
        owner.remove(c);
        furniture.add(c);
      }
    }
    region.clear();
  }
  final pieces = regions.where((r) => r.isNotEmpty).toList();
  rng.shuffle(pieces);

  // Keep enough boxes to reach the target coverage.
  final freeCount = pieces.fold<int>(0, (s, p) => s + p.length);
  final kept = <List<Cell>>[];
  var area = 0;
  for (final p in pieces) {
    if (area >= freeCount * d.coverage - 0.01 || kept.length == d.maxPieces) {
      break;
    }
    kept.add(p);
    area += p.length;
  }
  if (kept.length < 2) return null;

  final cats = <Cat>[];
  final boxes = <BoxPiece>[];
  for (final region in kept) {
    final shape = Shape(region);
    final origin = (
      region.map((c) => c.$1).reduce(min),
      region.map((c) => c.$2).reduce(min),
    );
    var trait = CatTrait.none;
    if (rng.chance(d.traitChance)) {
      if (region.length <= kittenMaxBox) trait = CatTrait.kitten;
      if (region.length >= chonkMinBox) trait = CatTrait.chonk;
    }
    cats.add(Cat(rng.pick(region), trait, rng.nextInt(furPalette)));
    final turns = rng.nextInt(4);
    boxes.add(BoxPiece(shape.rotatedBy(turns), (4 - turns) % 4, origin));
  }
  rng.shuffle(boxes);

  return Level(
    rows: n,
    cols: n,
    furniture: furniture,
    cats: cats,
    pieces: boxes,
  );
}
