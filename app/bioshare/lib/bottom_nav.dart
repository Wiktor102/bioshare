import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int tabIndex;
  final Function(int) changeTab;

  const BottomNav({
    super.key,
    required this.tabIndex,
    required this.changeTab,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: tabIndex,
      onDestinationSelected: (index) {
        changeTab(index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.location_on),
          label: "W pobliżu",
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: "Szukaj",
        ),
        NavigationDestination(
          icon: Icon(Icons.kitchen),
          label: "Moje",
        ),
      ],
    );
  }
}
