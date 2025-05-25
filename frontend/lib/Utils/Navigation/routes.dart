import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/View/Authentication/login.dart';
import 'package:frontend/View/Authentication/sign_up.dart';
import 'package:frontend/View/Interface/Feed/interface_page.dart';
import 'package:frontend/View/Interface/home_page.dart';
import 'package:frontend/View/Splash/splash_screen.dart';
import 'package:frontend/View/welcome_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return CupertinoPageRoute(builder: (context) => const SplashScreen());
      case '/welcome_page':
        return CupertinoPageRoute(builder: (context) => const WelcomePage());
      case '/login':
        return CupertinoPageRoute(builder: (context) => const LoginPage());
      case '/sign_up':
        return CupertinoPageRoute(builder: (context) => const RegisterPage());
      case '/home':
        return CupertinoPageRoute(builder: (context) => const HomePage());
      case '/interface':
        return CupertinoPageRoute(builder: (context) => const InterfacePage());
      default:
        return CupertinoPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text("No route Defined for ${settings.name}"),
            ),
          ),
        );
    }
  }
}
