import "package:bioshare/signup.dart";
import 'package:flutter/material.dart';

import 'app/app_structure.dart';
import "./login.dart";

void main() {
  runApp(const App());
}

enum View { appView, loginView, signupView }

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  View currentView = View.loginView;

  setView(View newView) {
    setState(() => currentView = newView);
  }

  Widget getView() {
    if (currentView == View.loginView) {
      return LoginPage(() => setView(View.signupView), () => setView(View.appView));
    }

    if (currentView == View.signupView) {
      return SignupPage(() => setView(View.loginView));
    }

    return AppStructure(goToLogin: () => setView(View.loginView));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bioshare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 69, 182, 242),
          secondary: const Color(0xff00ab8f),
        ),
        useMaterial3: true,
      ),
      home: getView(),
    );
  }
}
