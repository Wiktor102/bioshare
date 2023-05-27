import 'package:bioshare/app/app_bar.dart';
import 'package:flutter/material.dart';

class FridgeDetails extends StatelessWidget {
  final Function() goToLogin;

  const FridgeDetails({required this.goToLogin, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: CustomAppBar(
          title: "Szczegóły",
          goToLogin: () {
            Navigator.of(context).pop();
            goToLogin();
          },
        ),
      ),
      body: const Placeholder(),
    );
  }
}
