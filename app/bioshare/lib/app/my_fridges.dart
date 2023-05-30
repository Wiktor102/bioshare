import 'package:flutter/material.dart';

class MyFridges extends StatelessWidget {
  const MyFridges({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Dodaj lodówkę"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
