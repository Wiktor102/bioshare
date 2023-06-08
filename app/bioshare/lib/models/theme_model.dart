import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { auto, light, dark }

class ThemeModel extends ChangeNotifier {
  AppTheme _theme = AppTheme.auto;
  late Brightness _systemBrightness;
  Brightness? _appBrightness;

  Brightness get brightness => _appBrightness ?? _systemBrightness;
  AppTheme get theme => _theme;

  set theme(AppTheme newTheme) {
    (() async {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.setString('theme', newTheme.name);
    })();

    _theme = newTheme;
    setAppBrightnessFromTheme();
    notifyListeners();
  }

  setAppBrightnessFromTheme() {
    switch (_theme) {
      case AppTheme.light:
        _appBrightness = Brightness.light;
        break;
      case AppTheme.dark:
        _appBrightness = Brightness.dark;
        break;
      default:
        _appBrightness = _systemBrightness;
    }

    notifyListeners();
  }

  ThemeModel() {
    final window = SchedulerBinding.instance.platformDispatcher;
    _systemBrightness = window.platformBrightness;
    notifyListeners();

    (() async {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      _theme = AppTheme.values.byName(preferences.getString("theme") ?? "auto");
      setAppBrightnessFromTheme();
    })();

    window.onPlatformBrightnessChanged = () async {
      _systemBrightness = window.platformBrightness;

      final SharedPreferences preferences = await SharedPreferences.getInstance();
      final themeSetting = preferences.getString("theme");
      if (themeSetting == "auto") {
        _appBrightness = _systemBrightness;
      }

      notifyListeners();
    };
  }
}
