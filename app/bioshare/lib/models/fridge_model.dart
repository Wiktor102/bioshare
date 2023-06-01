import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class FridgeModel extends ChangeNotifier {
  List<Fridge> _fridges = [];
  get fridges => _fridges;

  FridgeModel() {
    _fridges.add(Fridge(
      id: 1,
      name: "Lodówka testowa",
      availableItems: [
        Item(name: "Brokuł"),
        Item(name: "Fasola"),
        Item(name: "Jogurt"),
        Item(name: "Mleko"),
        Item(name: "Marchewka"),
        Item(name: "Pomidor"),
      ],
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
}

class Item {
  String name;

  Item({required this.name});
}
