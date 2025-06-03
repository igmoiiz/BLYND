import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/providers/post_provider.dart';
import 'package:frontend/Utils/Navigation/routes.dart';
import 'package:frontend/Utils/Theme/theme.dart';
import 'package:frontend/Utils/consts.dart';
import 'package:frontend/View/Splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabase_url,
    anonKey: supabase_anonKey,
  );
  // await ApiService.initDio();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: lightMode,
        darkTheme: darkMode,
        themeMode: ThemeMode.dark,
        title: "BLYND",
        onGenerateRoute: Routes.generateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}
