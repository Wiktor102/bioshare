import 'package:flutter/material.dart';

import './fridges_list.dart';
import './app_bar.dart';
import "./bottom_nav.dart";

class AppStructure extends StatefulWidget {
  final Function() goToLogin;
  const AppStructure({required this.goToLogin, super.key});

  @override
  State<AppStructure> createState() => _AppStructureState();
}

class _AppStructureState extends State<AppStructure> {
  List titles = ["Lodówki w pobliżu", "Szukaj", "Moje lodówki"];
  int tabIndex = 0;
  late List screens;

  @override
  initState() {
    super.initState();
    screens = [
      FridgesList(goToLogin: widget.goToLogin),
      const Text("Tab 2"),
      const Text("Tab 3"),
    ];
  }

  changeTab(int i) {
    setState(() => tabIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: CustomAppBar(title: titles[tabIndex], goToLogin: widget.goToLogin),
      ),
      body: screens[tabIndex],
      bottomNavigationBar: BottomNav(tabIndex: tabIndex, changeTab: changeTab),
    );
  }
}
