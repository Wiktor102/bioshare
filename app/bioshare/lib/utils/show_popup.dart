import 'package:flutter/material.dart';

void showPopup(BuildContext context, String title, String? content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: content == null ? null : Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
