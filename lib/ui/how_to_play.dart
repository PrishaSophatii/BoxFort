import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/level.dart';
import 'board.dart';
import 'palette.dart';
import 'widgets.dart';

Future<void> showHowToPlay(BuildContext context) => showDialog(
  context: context,
  builder: (context) => Dialog(
    backgroundColor: Palette.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'How to play',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _step(
            const CatTile(
              cat: Cat((0, 0), CatTrait.none, 0),
              mood: CatMood.happy,
              size: 44,
            ),
            'Every cat wants its own box. Drag boxes onto the floor so each box holds exactly one cat.',
          ),
          _step(
            boxView(Shape(const [(0, 0), (1, 0), (1, 1)]), 20),
            'Tap a box to turn it. Boxes can\'t go on furniture or overlap.',
          ),
          _step(
            const CatTile(
              cat: Cat((0, 0), CatTrait.none, 1),
              mood: CatMood.crowded,
              size: 44,
            ),
            'Two cats in one box? They\'ll fight. Use every box.',
          ),
          _step(
            const CatTile(
              cat: Cat((0, 0), CatTrait.kitten, 3),
              mood: CatMood.waiting,
              size: 44,
            ),
            'Kittens wear a bow and fit in boxes of $kittenMaxBox cells or less.',
          ),
          _step(
            const CatTile(
              cat: Cat((0, 0), CatTrait.chonk, 2),
              mood: CatMood.waiting,
              size: 44,
            ),
            'Big cats need a roomy box of $chonkMinBox cells or more.',
          ),
          const SizedBox(height: 8),
          BigButton(
            label: 'Let\'s play',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  ),
);

Widget _step(Widget art, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: Row(
    children: [
      SizedBox(width: 52, height: 44, child: Center(child: art)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Palette.ink, height: 1.3),
        ),
      ),
    ],
  ),
);
