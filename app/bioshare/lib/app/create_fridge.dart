import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// common
import '../common/custom_card.dart';
import '../common/location_picker.dart';

// utilities
import '../main.dart';
import '../utils/session_expired.dart';
import '../utils/show_popup.dart';

// model classes
import '../models/fridge_model.dart';

// common components
import './app_bar.dart';

class CreateFridge extends StatefulWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  CreateFridge({super.key});

  @override
  State<CreateFridge> createState() => _CreateFridgeState();
}

class _CreateFridgeState extends State<CreateFridge> {
  String name = "";
  String address = "";
  String description = "";
  LatLng? location;
  bool test = false;

  addFridge(BuildContext context) async {
    if (widget._formKey.currentState?.validate() == false) {
      return;
    }

    if (location == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Podaj lokalizację"),
          content: const Text("Użyj mapy aby wskazać gdzie dokładnie znajduje się lodówka"),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      return;
    }

    widget._formKey.currentState?.save();

    final String body = json.encode({
      "name": name,
      "address": address,
      "description": description,
      "location": [location!.latitude, location!.longitude],
      "test": test ? 1 : 0,
    });

    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/fridge.php");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/fridge.php");
    }

    String? jwt = await App.secureStorage.read(key: "jwt");

    if (jwt == null) {
      if (context.mounted) {
        sessionExpired(context);
      }
      return;
    }

    try {
      final http.Response response = await http.post(
        uri,
        body: body,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $jwt',
        },
      );

      if (response.statusCode == 403) {
        if (context.mounted) {
          sessionExpired(context);
        }
        return;
      }

      if (response.body == "") {
        throw Exception(response.statusCode);
      }

      dynamic decodedResponse;

      try {
        decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      } catch (e) {
        throw Exception(response.body);
      }

      if (response.statusCode == 200) {
        final String username = await App.secureStorage.read(key: "username") ?? "?";
        final Fridge newFridge = Fridge(
            id: decodedResponse["id"],
            name: decodedResponse["name"],
            adminId: decodedResponse["admin"],
            location: LatLng(decodedResponse["location"][0], decodedResponse["location"][1]),
            description: decodedResponse["description"],
            availableItems: [],
            adminUsername: username,
            test: test);

        if (context.mounted) {
          Provider.of<FridgeModel>(context, listen: false).addFridge(newFridge);
          Navigator.of(context).pop();
        }
      } else {
        print(response.statusCode);
        throw Exception(decodedResponse.error);
      }
    } catch (e) {
      print(e);

      if (context.mounted) {
        showPopup(context, "Wystąpił nieznany błąd", "Przepraszamy. Proszę spróbować później.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: CustomAppBar(
            title: "Stwórz lodówkę",
          ),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: widget._formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    onSaved: (newValue) => name = (newValue ?? ""),
                    validator: (String? value) {
                      if (value == "" || value == null) return "Nazwa jest wymagana";
                      if (value.length > 60) return "Nazwa musi mieć ≤ 50 znaków";
                      return null;
                    },
                    decoration: gedInputDecoration(
                      context,
                      labelText: "Nazwa",
                      hintText: "Nazwij lodówkę",
                      icon: Icons.abc,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    onSaved: (newValue) => address = (newValue ?? ""),
                    decoration: gedInputDecoration(
                      context,
                      labelText: "Adres",
                      hintText: "",
                      icon: Icons.pin_drop,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    onSaved: (newValue) => description = (newValue ?? ""),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if ((value?.length ?? 0) > 1000) {
                        return "Max. 1000 znaków";
                      }

                      return null;
                    },
                    maxLines: null,
                    decoration: gedInputDecoration(
                      context,
                      labelText: "Opis",
                      hintText: "Jeśli chcesz możesz dodać opis",
                      icon: Icons.description,
                      borderRadius: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomCard(
                      title: "Wskaż miejsce lodówki",
                      children: [
                        SizedBox(
                          height: 170,
                          child: LocationPicker(
                            onSelected: (nl) => setState(() => location = nl),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomCard(
                    title: "Inne",
                    children: [
                      ListTile(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Lodówka testowa"),
                            Tooltip(
                              key: widget._tooltipKey,
                              message: "Zaznacz to pole jeśli lodówka nie istnieje naprawdę",
                              showDuration: const Duration(seconds: 4),
                              triggerMode: TooltipTriggerMode.manual,
                              child: IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () {
                                  widget._tooltipKey.currentState?.ensureTooltipVisible();
                                },
                              ),
                            ),
                          ],
                        ),
                        leading: const Icon(Icons.biotech),
                        trailing: Switch(
                          value: test,
                          onChanged: (newState) => setState(() {
                            test = newState;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => addFridge(context),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.done),
        ),
      ),
    );
  }

  InputDecoration gedInputDecoration(
    BuildContext context, {
    required String labelText,
    required String hintText,
    required IconData icon,
    double borderRadius = 100,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      fillColor: Colors.white,
      icon: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
    );
  }
}
