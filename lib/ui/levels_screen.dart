import 'package:flutter/material.dart';

import '../services/progress.dart';
import 'game_screen.dart';
import 'palette.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        foregroundColor: Palette.ink,
        title: const Text(
          'Levels',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListenableBuilder(
        listenable: Progress.instance,
        builder: (context, _) {
          final unlocked = Progress.instance.unlocked;
          // Levels are generated, so the list only needs to run a bit past
          // where the player is.
          final shown = ((unlocked + 30) / 5).ceil() * 5;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 76,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: shown,
            itemBuilder: (context, i) {
              final n = i + 1;
              final open = n <= unlocked;
              final done = n < unlocked;
              return Material(
                color: done
                    ? Palette.cardboard
                    : open
                    ? Palette.accent
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: open
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(puzzle: Puzzle.level(n)),
                          ),
                        )
                      : null,
                  child: Center(
                    child: open
                        ? Text(
                            '$n',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : Icon(
                            Icons.lock_rounded,
                            color: Palette.inkSoft.withValues(alpha: 0.5),
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
