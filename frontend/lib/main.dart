import 'package:flutter/material.dart';
import 'package:frontend/Utils/consts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Supabase_Url, anonKey: Supabase_Anon_Key);
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
      home: SplashScreen(),
    );
  }
}
