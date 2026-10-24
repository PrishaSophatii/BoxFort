import 'package:flutter/material.dart';

import '../services/ads.dart';
import '../services/progress.dart';
import 'game_screen.dart';
import 'how_to_play.dart';
import 'levels_screen.dart';
import 'palette.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _privacyButton = false;

  @override
  void initState() {
    super.initState();
    Ads.instance.privacyOptionsRequired().then((v) {
      if (mounted) setState(() => _privacyButton = v);
    });
  }

  void _open(Puzzle puzzle) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => GameScreen(puzzle: puzzle)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Progress.instance,
          builder: (context, _) {
            final p = Progress.instance;
            final streak = p.liveStreak;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const CatInBox(size: 150),
                      const SizedBox(height: 12),
                      const Text(
                        'Box Fort',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Palette.ink,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'Every cat needs a box.',
                        style: TextStyle(fontSize: 17, color: Palette.inkSoft),
                      ),
                      const SizedBox(height: 36),
                      BigButton(
                        label: 'Play · Level ${p.unlocked}',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => _open(Puzzle.level(p.unlocked)),
                      ),
                      const SizedBox(height: 12),
                      BigButton(
                        label: p.dailyDoneToday
                            ? 'Daily puzzle ✓'
                            : 'Daily puzzle',
                        icon: Icons.wb_sunny_rounded,
                        secondary: true,
                        trailing: streak > 0 ? Text('🔥 $streak') : null,
                        onPressed: () => _open(Puzzle.daily(DateTime.now())),
                      ),
                      const SizedBox(height: 12),
                      BigButton(
                        label: 'All levels',
                        icon: Icons.grid_view_rounded,
                        secondary: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LevelsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => showHowToPlay(context),
                            icon: const Icon(Icons.help_outline_rounded),
                            label: const Text('How to play'),
                          ),
                          if (_privacyButton)
                            TextButton.icon(
                              onPressed: Ads.instance.showPrivacyOptions,
                              icon: const Icon(Icons.privacy_tip_outlined),
                              label: const Text('Privacy'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
