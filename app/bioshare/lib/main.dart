import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'app/app_structure.dart';
import "./signup.dart";
import "./login.dart";

import './models/fridge_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FridgeModel()),
      ],
      child: const App(),
    ),
  );
}

enum View { appView, loginView, signupView }

class App extends StatefulWidget {
  static var secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

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
