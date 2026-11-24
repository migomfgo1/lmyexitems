import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'src/screens/splash_screen.dart';
import 'src/state.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await PhotoStore.init();
  final AppState state = await AppState.load();
  runApp(LMyExItemsApp(state: state));
}

class LMyExItemsApp extends StatelessWidget {
  const LMyExItemsApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'L my ex items',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
