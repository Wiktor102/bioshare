import 'package:flutter/material.dart';

enum View { appView, loginView, signupView }

class ViewModel extends ChangeNotifier {
  View currentView = View.loginView;

  setView(View newView) {
    currentView = newView;
    notifyListeners();
  }

  goToLogin() {
    setView(View.loginView);
  }
}
