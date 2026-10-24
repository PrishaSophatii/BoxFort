import 'package:box_fort/game/game_state.dart';
import 'package:box_fort/game/generator.dart';
import 'package:box_fort/game/level.dart';
import 'package:flutter_test/flutter_test.dart';

// First three cat cells of level 30, as produced on the Dart VM.
const pinnedLevel30Cats = [(4, 2), (0, 0), (0, 3)];

void main() {
  test('shapes rotate back to themselves after four turns', () {
    final l = Shape([(0, 0), (1, 0), (2, 0), (2, 1)]);
    expect(l.rotatedBy(4).cells, l.cells);
    expect(l.rotated().rows, 2);
    expect(l.rotated().cols, 3);
  });

  test('levels look the same on every platform', () {
    // Run with --platform chrome too: web must agree with the phone builds.
    final l = generateCampaignLevel(30);
    expect(
      [for (final c in l.cats) c.cell].take(3).toList(),
      pinnedLevel30Cats,
    );
  });

  test('levels are deterministic', () {
    final a = generateCampaignLevel(42);
    final b = generateCampaignLevel(42);
    expect(a.furniture, b.furniture);
    expect([for (final c in a.cats) c.cell], [for (final c in b.cats) c.cell]);
  });

  test('every generated level is solved by its stored solution', () {
    final levels = [
      for (var n = 1; n <= 300; n++) generateCampaignLevel(n),
      for (var d = 0; d < 60; d++)
        generateDailyLevel(DateTime(2026, 1, 1).add(Duration(days: d))),
    ];
    for (final level in levels) {
      expect(level.cats.length, level.pieces.length);
      final game = GameState(level);
      expect(game.solved, isFalse);
      for (var i = 0; i < level.pieces.length; i++) {
        final p = level.pieces[i];
        game.turns[i] = p.solutionTurns;
        expect(game.place(i, p.solutionOrigin), isTrue);
      }
      expect(game.solved, isTrue);
    }
  });

  test('hints alone solve a level', () {
    final game = GameState(generateCampaignLevel(30));
    while (game.hint()) {}
    expect(game.solved, isTrue);
  });

  test('a crowded box makes cats unhappy', () {
    final level = Level(
      rows: 1,
      cols: 3,
      furniture: {},
      cats: const [
        Cat((0, 0), CatTrait.none, 0),
        Cat((0, 1), CatTrait.none, 0),
      ],
      pieces: [
        BoxPiece(Shape([(0, 0), (0, 1)]), 0, (0, 0)),
      ],
    );
    final game = GameState(level)..place(0, (0, 0));
    expect(game.moodOf(0), CatMood.crowded);
    expect(game.solved, isFalse);
  });
}
