import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import './show_popup.dart';
import '../models/view_model.dart';

sessionExpired(BuildContext? context) async {
  context ??= App.navigatorKey.currentContext;
  if (context == null) return;

  Navigator.of(context).pop();
  await App.secureStorage.delete(key: "jwt");

  // We can delete the refreshToken beacuse it's invalid anyway
  await App.secureStorage.delete(key: "refreshToken");

  if (context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Provider.of<ViewModel>(context, listen: false).goToLogin();
    showPopup(context, "Twoja sesja wygasła", "musisz się zalogować ponownie");
  }
}
