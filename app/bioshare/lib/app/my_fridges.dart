import 'package:bioshare/common/app_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// model classes
import '../models/fridge_model.dart';

// widgets
import './fridges_list.dart';

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
      body: Consumer<FridgeModel>(builder: (context, provider, child) {
        return FutureBuilder(
            future: provider.getMyFridges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppBackground(child: Center(child: CircularProgressIndicator()));
              }

              return FridgesList(
                fridges: snapshot.data ?? [],
                listType: FridgeListType.admin,
              );
            });
      }),
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
