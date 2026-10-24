/// Small deterministic PRNG (Park–Miller). Unlike dart:math's Random, its
/// output is identical on every platform (including the web, where ints are
/// JavaScript doubles) and every Dart version, so a level number or daily
/// seed always produces the same puzzle for every player.
class Rng {
  static const _m = 2147483647; // 2^31 - 1
  static const _a = 48271;

  int _s;

  Rng(int seed) : _s = (seed % (_m - 1)) + 1 {
    for (var i = 0; i < 4; i++) {
      _next();
    }
  }

  // _s < 2^31 and _a < 2^16, so the product stays well inside 2^53.
  int _next() => _s = (_s * _a) % _m;

  /// Uniform-enough int in [0, max).
  int nextInt(int max) => _next() % max;

  double nextDouble() => (_next() - 1) / (_m - 1);

  bool chance(double p) => nextDouble() < p;

  T pick<T>(List<T> list) => list[nextInt(list.length)];

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }
}
