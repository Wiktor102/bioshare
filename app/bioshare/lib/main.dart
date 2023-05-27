import "package:bioshare/common/full_screen_loader.dart";
import "package:bioshare/signup.dart";
import 'package:flutter/material.dart';

import "./bottom_nav.dart";
import "./login.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bioshare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 69, 182, 242),
        ),
        useMaterial3: true,
      ),
      home: const App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

enum View { AppView, LoginView, SignupView }

class _AppState extends State<App> {
  View currentView = View.LoginView;
  int tabIndex = 0;
  List titles = ["Lodówki w pobliżu", "Szukaj", "Moje lodówki"];
  late List screens;

  changeTab(int i) {
    setState(() => tabIndex = i);
  }

  setView(View newView) {
    setState(() => currentView = newView);
  }

  _AppState() {
    screens = const [Text("Tab 1"), Text("Tab 2"), Text("Tab 3")];
  }

  @override
  Widget build(BuildContext context) {
    if (currentView == View.LoginView) {
      return LoginPage(() => setView(View.SignupView), () => setView(View.AppView));
    }

    if (currentView == View.SignupView) {
      return SignupPage(() => setView(View.LoginView));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(titles[tabIndex]),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle))],
        centerTitle: true,
      ),
      body: screens[tabIndex],
      bottomNavigationBar: BottomNav(tabIndex: tabIndex, changeTab: changeTab),
    );
  }
}
