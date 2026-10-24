import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../game/game_state.dart';
import '../game/generator.dart';
import '../game/level.dart';
import '../services/ads.dart';
import '../services/progress.dart';
import 'board.dart';
import 'how_to_play.dart';
import 'palette.dart';
import 'widgets.dart';

/// Either a campaign level number or a daily puzzle date.
class Puzzle {
  final int? number;
  final DateTime? day;

  const Puzzle.level(int this.number) : day = null;
  Puzzle.daily(DateTime d)
    : number = null,
      day = DateTime(d.year, d.month, d.day);

  bool get isDaily => day != null;

  Level build() =>
      isDaily ? generateDailyLevel(day!) : generateCampaignLevel(number!);

  String get title => isDaily
      ? 'Daily · ${_months[day!.month - 1]} ${day!.day}'
      : 'Level $number';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class GameScreen extends StatefulWidget {
  final Puzzle puzzle;

  const GameScreen({super.key, required this.puzzle});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Puzzle _puzzle = widget.puzzle;
  late GameState _game;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _start();
    final progress = Progress.instance;
    if (!progress.seenTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showHowToPlay(context);
        progress.markTutorialSeen();
      });
    }
  }

  void _start() {
    _game = GameState(_puzzle.build())..addListener(_onChange);
    _celebrated = false;
  }

  @override
  void dispose() {
    _game.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    setState(() {});
    if (_game.solved && !_celebrated) {
      _celebrated = true;
      Future.delayed(const Duration(milliseconds: 500), _win);
    }
  }

  Future<void> _win() async {
    if (!mounted) return;
    final progress = Progress.instance;
    var adDue = false;
    if (_puzzle.isDaily) {
      await progress.completeDaily(_puzzle.day!);
    } else {
      adDue = await progress.completeLevel(_puzzle.number!);
    }
    if (!mounted) return;
    final next = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinDialog(puzzle: _puzzle, moves: _game.moves),
    );
    if (adDue) await Ads.instance.showInterstitial();
    if (!mounted) return;
    if (next == true && !_puzzle.isDaily) {
      setState(() {
        _game.removeListener(_onChange);
        _puzzle = Puzzle.level(_puzzle.number! + 1);
        _start();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _hint() async {
    final progress = Progress.instance;
    if (progress.hints > 0) {
      if (_game.hint()) await progress.useHint();
      return;
    }
    final watch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Out of hints'),
        content: const Text(
          'Watch a short video to get 2 hints? You also earn a free hint every 5 levels.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Watch video'),
          ),
        ],
      ),
    );
    if (watch != true || !mounted) return;
    if (!Ads.supported) {
      // Web preview has no ads; hand out the hints so it stays playable.
      await progress.addHints(2);
      _toast('Preview build: ad skipped, +2 hints');
      return;
    }
    if (!Ads.instance.rewardedAvailable) {
      _toast('No video ready right now. Try again in a moment.');
      return;
    }
    if (await Ads.instance.showRewarded()) {
      await progress.addHints(2);
      _toast('+2 hints');
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final level = _game.level;
    final hasKittens = level.cats.any((c) => c.trait == CatTrait.kitten);
    final hasChonks = level.cats.any((c) => c.trait == CatTrait.chonk);
    return Scaffold(
      backgroundColor: Palette.background,
      bottomNavigationBar: const BannerSlot(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Palette.ink,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _puzzle.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Start over',
                    icon: const Icon(Icons.refresh_rounded),
                    color: Palette.ink,
                    onPressed: _game.placed.isEmpty ? null : _game.reset,
                  ),
                  ListenableBuilder(
                    listenable: Progress.instance,
                    builder: (context, _) => HintButton(
                      count: Progress.instance.hints,
                      onPressed: _game.solved ? null : _hint,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  const RuleChip(text: 'One cat per box'),
                  if (hasKittens)
                    const RuleChip(
                      text: 'Kittens (bow): $kittenMaxBox cells or less',
                    ),
                  if (hasChonks)
                    const RuleChip(text: 'Big cats: $chonkMinBox+ cells'),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final cell = [
                    (c.maxWidth - 32) / level.cols,
                    (c.maxHeight * 0.58) / level.rows,
                    64.0,
                  ].reduce((a, b) => a < b ? a : b);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Board(game: _game, cell: cell),
                        ),
                        const SizedBox(height: 16),
                        Tray(game: _game, boardCell: cell),
                        const SizedBox(height: 8),
                        const Text(
                          'Drag boxes onto the floor · tap a box to turn it',
                          style: TextStyle(
                            color: Palette.inkSoft,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinDialog extends StatelessWidget {
  final Puzzle puzzle;
  final int moves;

  const _WinDialog({required this.puzzle, required this.moves});

  @override
  Widget build(BuildContext context) {
    final streak = Progress.instance.liveStreak;
    return Dialog(
      backgroundColor: Palette.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CatInBox(size: 110),
            const SizedBox(height: 12),
            const Text(
              'All cats are napping!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              puzzle.isDaily
                  ? 'Daily puzzle solved in $moves moves · 🔥 $streak day streak'
                  : '${puzzle.title} solved in $moves moves',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.inkSoft),
            ),
            const SizedBox(height: 20),
            if (puzzle.isDaily) ...[
              BigButton(
                label: 'Share result',
                icon: Icons.ios_share_rounded,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'I tucked every cat into a box in Box Fort 📦🐱\n'
                        '${puzzle.title}: $moves moves · 🔥 $streak day streak',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              BigButton(
                label: 'Done',
                secondary: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ] else ...[
              BigButton(
                label: 'Next level',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 10),
              BigButton(
                label: 'Home',
                secondary: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
