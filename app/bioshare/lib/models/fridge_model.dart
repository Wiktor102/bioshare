import 'dart:convert';
import 'dart:io';
import 'package:bioshare/utils/session_expired.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import '../main.dart';

class FridgeModel extends ChangeNotifier {
  final List<Fridge> _fridges = [];
  final List<int> _fridgeIds = [];
  get fridges => _fridges;

  Fridge? getFridge(int id) => _getFridge(id);
  Fridge? _getFridge(int id) {
    return _fridges.firstWhere((element) => element.id == id);
  }

  void addFridge(Fridge newFridge) {
    if (_fridgeIds.contains(newFridge.id)) {
      return;
    }

    _fridges.add(newFridge);
    _fridgeIds.add(newFridge.id);
    notifyListeners();
  }

  List<Fridge> addFridgesFromApiResponse(List<dynamic> list) {
    List<Fridge> listAsFridges = [];
    for (var value in list) {
      final f = Fridge(
        id: value["id"] is int ? value["id"] : int.parse(value["id"]),
        name: value["name"],
        adminId: value["admin"] is int ? value["admin"] : int.parse(value["admin"]),
        location: LatLng(double.parse('${value["lat"]}'), double.parse('${value["lng"]}')),
        description: value["description"] == "" ? null : value["description"],
        availableItems: null,
        adminUsername: value["adminUsername"],
        test: value["test"] == "1", // MariaDB returns "0" or "1" so we need to convert it to bool
      );

      listAsFridges.add(f);
      addFridge(f);
    }

    return listAsFridges;
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

  setItemExpire(int fridgeId, int itemId, DateTime? newDate) async {
    final Fridge? f = _getFridge(fridgeId);
    if (f == null) return;

    await f.getItem(itemId)!.setExpire(newDate, notifyListeners);
  }

  setItemAmount(int fridgeId, int itemId, double? newAmount) async {
    final Fridge? f = _getFridge(fridgeId);
    if (f == null) return;

    await f.getItem(itemId)!.setAmount(newAmount, notifyListeners);
  }

  Future<(List<Fridge>, Map<int, int>)> search(String query, ItemCategory? category, bool nearExpire) async {
    final String categoryString = category?.name ?? "";
    final queryString = "q=$query&category=$categoryString&nearExpire=$nearExpire";

    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/fridge.php/search?$queryString");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/fridge.php/search?$queryString");
    }
    String? jwt = await App.secureStorage.read(key: "jwt");

    if (jwt == null) {
      return ([] as List<Fridge>, {} as Map<int, int>);
    }

    try {
      final http.Response response = await http.get(
        uri,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $jwt',
        },
      );

      if (response.statusCode == 404) {
        return ([] as List<Fridge>, {} as Map<int, int>);
      }

      if (response.statusCode != 200 && response.body == "") {
        throw Exception(response.statusCode);
      }

      dynamic decodedResponse;

      try {
        decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        throw Exception(e);
      }

      if (response.statusCode != 200) {
        throw Exception(decodedResponse["error"]);
      }

      Map<int, int> matchingResultsMap = {};
      decodedResponse.forEach((f) => matchingResultsMap[f["id"]] = f["itemCount"]);
      return (addFridgesFromApiResponse(decodedResponse), matchingResultsMap);
    } catch (e, stack) {
      print(e);
      print(stack);
      return ([] as List<Fridge>, {} as Map<int, int>);
    }
  }

  Future<bool> deleteFridge(int id) async {
    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/fridge.php/$id");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/fridge.php/$id");
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

      if (response.statusCode == 200) {
        _fridges.removeWhere((element) => element.id == id);
        notifyListeners();
        return true;
      }

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
    } catch (e, stack) {
      print(e);
      print(stack);
    }

    return false;
  }

  Future<void> editFridgeDescription(int fridgeId, String newDescription) async {
    await _getFridge(fridgeId)?.editDescription(newDescription, notifyListeners);
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

      addFridgesFromApiResponse(decodedResponse);
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
          category: ItemCategory.values.byName(value["category"].isEmpty ? "others" : value["category"]),
          amount: value["amount"] == null ? null : double.parse(value["amount"].toString()),
          unit: value["unit"],
          fridgeId: int.parse(value["fridge"].toString()),
          expire: value["expire"] == null ? null : DateTime.parse(value["expire"]),
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

enum ItemCategory {
  fruits,
  vegetables,
  diary,
  meat,
  dishes,
  others;

  String toString() {
    switch (this) {
      case ItemCategory.fruits:
        return "Owoce";
      case ItemCategory.vegetables:
        return "Warzywa";
      case ItemCategory.diary:
        return "Nabiał";
      case ItemCategory.meat:
        return "Mięso";
      case ItemCategory.dishes:
        return "Dania gotowe";
      case ItemCategory.others:
        return "Inne";
    }
  }
}

class Item {
  int id;
  int fridgeId;
  String name;
  ItemCategory category;
  double? amount;
  String? unit;
  DateTime? expire;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.unit,
    required this.fridgeId,
    required this.expire,
  });

  Future<bool> setExpire(DateTime? newExpire, VoidCallback notifyListeners) async {
    final oldDate = expire;
    expire = newExpire;
    notifyListeners();

    final body =
        json.encode({"newExpireDate": newExpire != null ? DateFormat("yyyy-MM-dd").format(newExpire) : null});

    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/item.php/$id/expire");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/item.php/$id/expire");
    }
    String? jwt = await App.secureStorage.read(key: "jwt");

    if (jwt == null) {
      return false;
    }

    try {
      final http.Response response = await http.patch(
        uri,
        body: body,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $jwt',
        },
      );

      if (response.statusCode == 403) {
        sessionExpired(null);
      }

      if (response.statusCode != 200) {
        expire = oldDate;
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

      return true;
    } catch (e, stack) {
      print(e);
      print(stack);
      return false;
    }
  }

  Future<bool> setAmount(double? newAmount, VoidCallback notifyListeners) async {
    final oldAmount = amount;
    amount = newAmount;
    notifyListeners();

    final body = json.encode({"newAmount": newAmount});

    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/item.php/$id/amount");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/item.php/$id/amount");
    }
    String? jwt = await App.secureStorage.read(key: "jwt");

    if (jwt == null) {
      return false;
    }

    try {
      final http.Response response = await http.patch(
        uri,
        body: body,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $jwt',
        },
      );

      if (response.statusCode == 403) {
        sessionExpired(null);
      }

      if (response.statusCode != 200) {
        amount = oldAmount;
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

      return true;
    } catch (e, stack) {
      print(e);
      print(stack);
      return false;
    }
  }

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
