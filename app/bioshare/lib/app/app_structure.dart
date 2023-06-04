import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './fridges_list.dart';
import './app_bar.dart';
import "./bottom_nav.dart";
import './my_fridges.dart';
import '../models/fridge_model.dart';

class AppStructure extends StatefulWidget {
  final Function() goToLogin;
  const AppStructure({required this.goToLogin, super.key});

  @override
  State<AppStructure> createState() => _AppStructureState();
}

class _AppStructureState extends State<AppStructure> {
  List titles = ["Lodówki w pobliżu", "Szukaj", "Moje lodówki"];
  int tabIndex = 0;

  changeTab(int i) {
    setState(() => tabIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final FridgeModel provider = Provider.of<FridgeModel>(context);

    final List<Widget> screens = [
      FridgesList(
        goToLogin: widget.goToLogin,
        fridges: provider.fridges,
      ),
      const Text("Tab 2"),
      MyFridges(
        goToLogin: widget.goToLogin,
      ),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: CustomAppBar(title: titles[tabIndex]),
      ),
      body: screens[tabIndex],
      bottomNavigationBar: BottomNav(tabIndex: tabIndex, changeTab: changeTab),
    );
  }
}
