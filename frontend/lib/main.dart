import 'package:flutter/material.dart';
import 'package:frontend/Utils/Navigation/routes.dart';
import 'package:frontend/Utils/Theme/theme.dart';
import 'package:frontend/Utils/consts.dart';
import 'package:frontend/View/Splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabase_url, anonKey: supabase_anonKey);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // debugShowMaterialGrid: true,
      theme: lightMode,
      darkTheme: darkMode,
      title: "BLYND",
      onGenerateRoute: Routes.generateRoute,
      home: const SplashScreen(),
    );
  }
}
