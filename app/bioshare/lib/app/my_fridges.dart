import 'package:flutter/material.dart';

// widgets
import './create_fridge.dart';

class MyFridges extends StatelessWidget {
  const MyFridges({super.key});

  void addFridge(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateFridge(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addFridge(context),
        label: const Text("Dodaj lodówkę"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
