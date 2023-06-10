import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/app_structure.dart';
import "./signup.dart";
import "./login.dart";

// model classes / providers
import './models/theme_model.dart';
import './models/fridge_model.dart';
import './models/location_model.dart';
import './models/view_model.dart' as AppViews;

void main() async {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationModel()),
        ChangeNotifierProvider(create: (_) => FridgeModel()),
        ChangeNotifierProvider(create: (_) => ThemeModel()),
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

  static var navigatorKey = GlobalKey<NavigatorState>();
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

  final Color secondaryLight = const Color(0xff00ab8f);
  final Color secondaryDark = const Color(0xff018576);

  final Color surfaceVariantLight = const Color(0xffbcdefc);
  final Color surfaceVariantDark = const Color(0xff3c81c2);

  final Color onSurfaceVariantLight = const Color(0xff135f7e);
  final Color onSurfaceVariantDark = const Color(0xff004080);

  final Color surfaceTintLight = const Color(0xffbcdefc);
  final Color surfaceTintDark = const Color(0xff2a353e);

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeModel, Brightness>(
      selector: (context, themeProvider) => themeProvider.brightness,
      builder: (context, b, child) {
        return MaterialApp(
          title: 'Bio-Share',
          navigatorKey: App.navigatorKey,
          theme: ThemeData(
            primaryColorDark: const Color(0xff2a353e),
            secondaryHeaderColor: b == Brightness.light ? null : const Color(0xff415263),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 69, 182, 242),
              secondary: b == Brightness.light ? secondaryLight : secondaryDark,
              surfaceVariant: b == Brightness.light ? surfaceVariantLight : surfaceVariantDark,
              onError: b == Brightness.light ? onSurfaceVariantLight : onSurfaceVariantDark,
              surfaceTint: b == Brightness.light ? surfaceTintLight : surfaceTintDark,

              //   onSurface: b == Brightness.light ? null : Colors.white,
              primary: b == Brightness.light ? null : const Color(0xff77c2eb),
              brightness: b,
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
          home: child,
        );
      },
      child: Consumer<AppViews.ViewModel>(
        builder: (context, provider, child) {
          return getView(provider);
        },
      ),
    );
  }
}
