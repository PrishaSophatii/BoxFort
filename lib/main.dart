import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/ads.dart';
import 'services/progress.dart';
import 'ui/home_screen.dart';
import 'ui/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Progress.load();
  runApp(const BoxFortApp());
  // Consent and ad loading run after the first frame so startup stays fast.
  Ads.instance.init();
}

class BoxFortApp extends StatelessWidget {
  const BoxFortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Box Fort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.accent,
          surface: Palette.background,
        ),
        scaffoldBackgroundColor: Palette.background,
        useMaterial3: true,
        fontFamily: 'Nunito',
      ),
      home: const HomeScreen(),
    );
  }
}
