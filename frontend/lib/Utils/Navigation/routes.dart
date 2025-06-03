import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/View/Authentication/login.dart';
import 'package:frontend/View/Authentication/sign_up.dart';
import 'package:frontend/View/Interface/Feed/interface_page.dart';
import 'package:frontend/View/Interface/home_page.dart';
import 'package:frontend/View/Interface/Settings/edit_profile_page.dart';
import 'package:frontend/View/Interface/Settings/help_page.dart';
import 'package:frontend/View/Interface/Settings/privacy_policy_page.dart';
import 'package:frontend/View/Interface/Settings/privacy_settings_page.dart';
import 'package:frontend/View/Interface/Profile/user_profile_page.dart';
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

      // Settings Pages
      case '/edit_profile':
        return CupertinoPageRoute(
            builder: (context) => const EditProfilePage());
      case '/privacy_settings':
        return CupertinoPageRoute(
            builder: (context) => const PrivacySettingsPage());
      case '/privacy_policy':
        return CupertinoPageRoute(
            builder: (context) => const PrivacyPolicyPage());
      case '/help':
        return CupertinoPageRoute(builder: (context) => const HelpPage());

      // Profile Pages
      case '/user_profile':
        final args = settings.arguments as Map<String, dynamic>;
        return CupertinoPageRoute(
          builder: (context) => UserProfilePage(
            userId: args['userId'] as String,
            userName: args['userName'] as String,
          ),
        );

      default:
        return CupertinoPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text("No route defined for ${settings.name}"),
            ),
          ),
        );
    }
  }
}
