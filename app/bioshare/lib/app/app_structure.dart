import 'package:flutter/material.dart';
import "./bottom_nav.dart";

class AppStructure extends StatefulWidget {
  const AppStructure({super.key});

  @override
  State<AppStructure> createState() => _AppStructureState();
}

class _AppStructureState extends State<AppStructure> {
  List titles = ["Lodówki w pobliżu", "Szukaj", "Moje lodówki"];
  int tabIndex = 0;
  late List screens;

  _AppStructureState() {
    screens = const [
      Text("Tab 1"),
      Text("Tab 2"),
      Text("Tab 3"),
    ];
  }

  changeTab(int i) {
    setState(() => tabIndex = i);
  }

  @override
  Widget build(BuildContext context) {
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
