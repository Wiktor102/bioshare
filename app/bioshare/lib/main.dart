import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/app_structure.dart';
import "./signup.dart";
import "./login.dart";

import './models/view_model.dart' as AppViews;
import './models/fridge_model.dart';
import './models/location_model.dart';

void main() async {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationModel()),
        ChangeNotifierProvider(create: (_) => FridgeModel()),
        ChangeNotifierProvider(create: (_) => AppViews.ViewModel()),
      ],
      child: const App(),
    ),
  );
}

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
  Widget getView(AppViews.ViewModel provider) {
    final currentView = provider.currentView;
    final setView = provider.setView;
    if (currentView == AppViews.View.loginView) {
      return LoginPage(() => setView(AppViews.View.signupView), () => setView(AppViews.View.appView));
    }

    if (currentView == AppViews.View.signupView) {
      return SignupPage(() => setView(AppViews.View.loginView));
    }

    return AppStructure(goToLogin: () => setView(AppViews.View.loginView));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bio-Share',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 69, 182, 242),
          secondary: const Color(0xff00ab8f),
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl'),
      ],
      home: Consumer<AppViews.ViewModel>(builder: (context, provider, child) {
        return getView(provider);
      }),
    );
  }
}
