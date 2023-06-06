import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import '../main.dart';

class FridgeModel extends ChangeNotifier {
  final List<Fridge> _fridges = [];
  get fridges => _fridges;

  void addFridge(Fridge newFridge) {
    if (_fridges.asMap().keys.toList().contains(newFridge.id)) {
      return;
    }

    _fridges.add(newFridge);
    notifyListeners();
  }

  Future<void> editFridgeDescription(int fridgeId, String newDescription) async {
    await _getFridge(fridgeId)?.editDescription(newDescription, notifyListeners);
  }

  Fridge? _getFridge(int id) {
    return _fridges.firstWhere((element) => element.id == id);
  }

  void addItem(int id, Item newItem) {
    _getFridge(id)?.addItem(newItem);
    notifyListeners();
  }

  Future<void> deleteItem(int fridgeId, int itemId) async {
    final Fridge? f = _getFridge(fridgeId);
    if (f == null) return;

    bool success = await f.getItem(itemId)!.delete();
    if (success) {
      f._availableItems!.removeWhere((Item item) => item.id == itemId);
      notifyListeners();
    }
  }

  Future<List<Fridge>> getMyFridges() async {
    final String? jwt = await App.secureStorage.read(key: "jwt");
    if (jwt == null) return [];
    final Map<String, dynamic> decodedJWT = Jwt.parseJwt(jwt);

    return _fridges.where((element) => element.adminId == decodedJWT["user_id"]).toList();
  }

  /// Fetches fridges from the database and saves them to the [_fridges] variable
  Future<void> _fetchFridges() async {
    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/fridge.php");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/fridge.php");
    }

    try {
      final http.Response response = await http.get(uri);

      if (response.body == "") {
        throw Exception(response.statusCode);
      }

      dynamic decodedResponse;

      try {
        decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        throw Exception(e);
      }

      if (response.statusCode != 200) {
        print(response.statusCode);
        throw Exception(decodedResponse["error"]);
      }

      decodedResponse = decodedResponse as List<dynamic>;
      for (var value in decodedResponse) {
        _fridges.add(Fridge(
          id: int.parse(value["id"]),
          name: value["name"],
          adminId: int.parse(value["admin"]),
          location: LatLng(double.parse(value["lat"]), double.parse(value["lng"])),
          description: value["description"],
          availableItems: null,
          adminUsername: value["adminUsername"],
          test: value["test"] == "1", // MariaDB returns "0" or "1" so we need to convert it to bool
        ));
      }

      notifyListeners();
    } catch (e, stack) {
      print(e);
      print(stack);
    }
  }

  Future<void> fetchFridgeItems(int fridgeId) async {
    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/fridge.php/$fridgeId/items");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/fridge.php/$fridgeId/items");
    }

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode == 404) {
        _getFridge(fridgeId)?._availableItems = [];
        notifyListeners();
        return;
      }

      if (response.body == "") {
        throw Exception(response.statusCode);
      }

      dynamic decodedResponse;

      try {
        decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        throw Exception(e);
      }

      if (response.statusCode != 200) {
        print(response.statusCode);
        throw Exception(decodedResponse["error"]);
      }

      decodedResponse = decodedResponse as List<dynamic>;
      List<Item> updatedItems = [];
      for (var value in decodedResponse) {
        updatedItems.add(Item(
          id: int.parse(value["id"].toString()),
          name: value["name"],
          amount: double.parse(value["amount"].toString()),
          unit: value["unit"],
          fridgeId: int.parse(value["fridge"].toString()),
          expire: DateTime.parse(value["expire"]),
        ));
      }

      _getFridge(fridgeId)?._availableItems = updatedItems;
      notifyListeners();
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print('Exception: $e');
        print('Stacktrace: $stacktrace');
      }
    }
  }

  FridgeModel() {
    _fetchFridges();
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
  List<Item>? _availableItems;
  bool test;
  DateTime? lastUpdatedItems;

  List<Item>? get availableItems => _availableItems;
  set availableItems(List<Item>? newValue) {
    _availableItems = newValue;
    lastUpdatedItems = DateTime.now();
  }

  Fridge({
    required this.id,
    required this.name,
    required List<Item>? availableItems,
    required this.adminId,
    required this.adminUsername,
    required this.location,
    required this.test,
    this.address,
    this.description,
  }) : _availableItems = availableItems {
    if (_availableItems != null) {
      lastUpdatedItems = DateTime.now();
    }
  }

  Future<void> editDescription(String newDescription, VoidCallback notifyListeners) async {
    final oldDescription = description;
    description = newDescription;
    notifyListeners();

    final body = json.encode({"description": newDescription});

    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/fridge.php/$id");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/fridge.php/$id");
    }
    String? jwt = await App.secureStorage.read(key: "jwt");

    if (jwt == null) {
      return;
    }

    try {
      final http.Response response = await http.patch(
        uri,
        body: body,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $jwt',
        },
      );

      if (response.statusCode != 200) {
        description = oldDescription;
        notifyListeners();

        if (response.body == "") {
          throw Exception(response.statusCode);
        }

        print(response.statusCode);
        dynamic decodedResponse;

        try {
          decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (e) {
          throw Exception(e);
        }

        throw Exception(decodedResponse["error"]);
      }
    } catch (e, stack) {
      print(e);
      print(stack);
    }
  }

  void addItem(Item item) {
    _availableItems ??= [];
    lastUpdatedItems = DateTime.now();

    if (_availableItems!.asMap().keys.toList().contains(item.id)) {
      return;
    }

    _availableItems!.add(item);
  }

  int getExpiredItems() {
    if (_availableItems == null) return 0;
    return _availableItems!.fold<int>(0, (value, item) {
      if (item.expire == null || DateTime.now().isBefore(item.expire!)) return value;
      return value + 1;
    });
  }

  Item? getItem(int id) {
    if (_availableItems == null) return null;
    return _availableItems!.firstWhere((element) => element.id == id);
  }
}

class Item {
  int id;
  int fridgeId;
  String name;
  double? amount;
  String? unit;
  DateTime? expire;

  Item({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.fridgeId,
    required this.expire,
  });

  Future<bool> delete() async {
    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/item.php/$id");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/item.php/$id");
    }

    String? jwt = await App.secureStorage.read(key: "jwt");

    if (jwt == null) {
      return false;
    }

    try {
      final http.Response response = await http.delete(
        uri,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $jwt',
        },
      );

      if (response.statusCode != 200) {
        throw Exception("#${response.statusCode}: ${response.body}");
      }

      return true;
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print('Exception: $e');
        print('Stacktrace: $stacktrace');
      }
      return false;
    }
  }
}
