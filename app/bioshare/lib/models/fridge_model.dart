import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class FridgeModel extends ChangeNotifier {
  final List<Fridge> _fridges = [];
  get fridges => _fridges;

  void addFridge(Fridge newFridge) {
    if (_fridges.asMap().keys.toList().contains(newFridge.id)) {
      return;
    }

    _fridges.add(newFridge);
  }

  Fridge? _getFridge(int id) {
    return _fridges.firstWhere((element) => element.id == id);
  }

  void addItem(int id, Item newItem) {
    _getFridge(id)?.addItem(newItem);
    notifyListeners();
  }

  FridgeModel() {
    _fridges.add(Fridge(
      id: 1,
      name: "Lodówka testowa",
      availableItems: [],
      adminId: 1,
      adminUsername: "Test",
      location: LatLng(50, 20),
      description: "Something",
      test: true,
    ));
  }
}

class Fridge {
  int id;
  String name;
  int adminId;
  String adminUsername;
  String? description;
  LatLng location;
  String? address;
  List<Item> availableItems;
  bool test;

  Fridge({
    required this.id,
    required this.name,
    required this.availableItems,
    required this.adminId,
    required this.adminUsername,
    required this.location,
    this.address,
    this.description,
    this.test = false,
  });

  addItem(Item item) {
    if (availableItems.asMap().keys.toList().contains(item.id)) {
      return;
    }

    availableItems.add(item);
  }
}

class Item {
  int id;
  int fridgeId;
  String name;
  double? amount;
  String? unit;

  Item({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.fridgeId,
  });
}
