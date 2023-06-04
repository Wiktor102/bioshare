import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import './show_popup.dart';
import '../models/view_model.dart';

sessionExpired(BuildContext context) async {
  Navigator.of(context).pop();
  showPopup(context, "Twoja sesja wygasła", "musisz się zalogować ponownie");
  await App.secureStorage.delete(key: "jwt");

  if (context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Provider.of<ViewModel>(context, listen: false).goToLogin();
  }
}
