import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved player progress.
class Progress extends ChangeNotifier {
  Progress._(this._prefs);
  static late Progress instance;

  final SharedPreferences _prefs;

  static Future<void> load() async {
    instance = Progress._(await SharedPreferences.getInstance());
  }

  static const startingHints = 3;

  /// Highest level the player may open (1-based).
  int get unlocked => _prefs.getInt('unlocked') ?? 1;
  int get hints => _prefs.getInt('hints') ?? startingHints;
  int get dailyStreak => _prefs.getInt('dailyStreak') ?? 0;
  String? get lastDaily => _prefs.getString('lastDaily');
  bool get seenTutorial => _prefs.getBool('seenTutorial') ?? false;
  int get levelsSinceAd => _prefs.getInt('levelsSinceAd') ?? 0;
  int get totalSolved => _prefs.getInt('totalSolved') ?? 0;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get dailyDoneToday => lastDaily == dayKey(DateTime.now());

  Future<void> _set(Future<bool> write) async {
    await write;
    notifyListeners();
  }

  Future<void> addHints(int n) => _set(_prefs.setInt('hints', hints + n));

  Future<void> useHint() => _set(_prefs.setInt('hints', hints - 1));

  Future<void> markTutorialSeen() => _set(_prefs.setBool('seenTutorial', true));

  /// Records a solved campaign level. Returns true if an interstitial is due.
  Future<bool> completeLevel(int level) async {
    if (level >= unlocked) await _prefs.setInt('unlocked', level + 1);
    final solved = totalSolved + 1;
    await _prefs.setInt('totalSolved', solved);
    // A free hint every 5 levels keeps hints from feeling paywalled.
    if (solved % 5 == 0) await _prefs.setInt('hints', hints + 1);
    // No ads during the first few levels, then one every third level.
    final since = levelsSinceAd + 1;
    final due = level > 5 && since >= 3;
    await _prefs.setInt('levelsSinceAd', due ? 0 : since);
    notifyListeners();
    return due;
  }

  Future<void> completeDaily(DateTime day) async {
    final today = dayKey(day);
    if (lastDaily == today) return;
    final yesterday = dayKey(day.subtract(const Duration(days: 1)));
    final streak = lastDaily == yesterday ? dailyStreak + 1 : 1;
    await _prefs.setInt('dailyStreak', streak);
    await _prefs.setString('lastDaily', today);
    notifyListeners();
  }
}

extension StreakView on Progress {
  /// The streak as shown to the player: it lapses if yesterday was missed.
  int get liveStreak {
    final now = DateTime.now();
    final last = lastDaily;
    if (last == Progress.dayKey(now) ||
        last == Progress.dayKey(now.subtract(const Duration(days: 1)))) {
      return dailyStreak;
    }
    return 0;
  }
}
