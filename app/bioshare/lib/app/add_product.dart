import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../app/app_bar.dart';
import '../main.dart';

// model classes / providers
import '../models/fridge_model.dart';
import '../models/theme_model.dart';

// utilities
import '../utils/session_expired.dart';
import '../utils/show_popup.dart';
import '../utils/refresh_access_token.dart';

class AddProduct extends StatefulWidget {
  final int fridgeId;
  const AddProduct({required this.fridgeId, super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String name = "";
  ItemCategory? category;
  double? amount;
  String? unit;
  DateTime? expireDate;

  bool provideAmount = false;
  bool provideExpireDate = false;

  _getToggleColor(BuildContext context) {
    final b = Provider.of<ThemeModel>(context).brightness;
    return b == Brightness.light
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.inversePrimary;
  }

  done(BuildContext context) async {
    _formKey.currentState!.save();
    if (!_formKey.currentState!.validate()) return;

    final String body = json.encode({
      "name": name,
      "category": category!.name,
      "amount": amount,
      "unit": unit,
      "expire": expireDate == null ? null : DateFormat("yyyy-MM-dd").format(expireDate!),
      "fridgeId": widget.fridgeId,
    });

    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/auth/getNewAccessToken.php");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/auth/getNewAccessToken.php");
    }

    String? jwt = await App.secureStorage.read(key: "jwt");

    if (jwt == null) {
      if (mounted) {
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
        await refreshAccessToken();

        if (mounted) {
          done(context);
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
        final Item newItem = Item(
          id: decodedResponse["id"],
          name: decodedResponse["name"],
          category: ItemCategory.values.byName(decodedResponse["category"]),
          amount: decodedResponse["amount"]?.toDouble(),
          unit: decodedResponse["unit"],
          fridgeId: decodedResponse["fridgeId"],
          expire: decodedResponse["expire"] == null ? null : DateTime.parse(decodedResponse["expire"]),
        );

        if (context.mounted) {
          final provider = Provider.of<FridgeModel>(context, listen: false);
          provider.addItem(widget.fridgeId, newItem);
        }
      } else {
        print(response.statusCode);
        throw Exception(decodedResponse.error);
      }
    } catch (e, s) {
      print(e);
      print(s);

      if (context.mounted) {
        showPopup(context, "Wystąpił nieznany błąd", "Przepraszamy. Proszę spróbować później.");
      }
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> setExpireDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: expireDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
        locale: const Locale("pl", "PL"));

    if (picked != null && picked != expireDate) {
      setState(() {
        expireDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: CustomAppBar(title: "Dodaj produkt"),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextFormField(
                  onSaved: (newValue) => name = (newValue ?? ""),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (String? value) {
                    if ((value?.isEmpty ?? true)) {
                      return "Podaj nazwę produktu";
                    }

                    if (value!.length > 200) {
                      return "Maksymalna długość nazwy = 200";
                    }

                    return null;
                  },
                  decoration: gedInputDecoration(
                    context,
                    labelText: "Nazwa",
                    hintText: "Wpisz nazwę produktu",
                    icon: Icons.abc,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text("Kategoria"),
                  leading: const Icon(Icons.category),
                  trailing: SizedBox(
                    width: 165,
                    child: DropdownButtonFormField<ItemCategory>(
                      decoration: const InputDecoration(
                        hintText: 'Wybierz',
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null) return "Wybierz kategorię";
                        return null;
                      },
                      value: category,
                      onChanged: (nc) => setState(() => category = nc),
                      items: ItemCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.toString()),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text("Chcę podać ilość"),
                  leading: const Icon(Icons.onetwothree),
                  trailing: Switch(
                    value: provideAmount,
                    activeColor: _getToggleColor(context),
                    onChanged: (newState) => setState(() => provideAmount = newState),
                  ),
                ),
                provideAmount
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              onSaved: (newValue) =>
                                  amount = (newValue != null ? (double.tryParse(newValue) ?? 0) : 0),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (String? value) {
                                if (value == null || double.tryParse(value) == null) {
                                  return "Wymagana liczba";
                                }
                                return null;
                              },
                              decoration: gedInputDecoration(
                                context,
                                labelText: "Ilość",
                                hintText: "",
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              onSaved: (newValue) => unit = (newValue ?? ""),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: gedInputDecoration(
                                context,
                                labelText: "Jednostka",
                                hintText: "",
                              ),
                              validator: (String? value) {
                                if ((value?.isEmpty ?? true)) {
                                  return "Podaj jednostkę";
                                }

                                if (value!.length > 10) {
                                  return "Max. długość jednostki = 10";
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      )
                    : Container(),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text("Produkt ma termin ważności"),
                  leading: const Icon(Icons.calendar_month),
                  trailing: Switch(
                    value: provideExpireDate,
                    activeColor: _getToggleColor(context),
                    onChanged: (newState) => setState(() => provideExpireDate = newState),
                  ),
                ),
                provideExpireDate
                    ? ListTile(
                        title: const Text("Termin ważności"),
                        leading: const Icon(Icons.calendar_month),
                        trailing: expireDate == null
                            ? Selector<ThemeModel, Brightness>(
                                selector: (context, themeProvider) => themeProvider.brightness,
                                builder: (context, b, child) {
                                  return ElevatedButton(
                                    onPressed: () => setExpireDate(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: b == Brightness.light
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.inversePrimary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Ustaw"),
                                  );
                                })
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('dd.MM.yyyy').format(expireDate!),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  IconButton(
                                    onPressed: () => setExpireDate(context),
                                    icon: const Icon(Icons.edit),
                                  ),
                                ],
                              ),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => done(context),
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
    IconData? icon,
    double borderRadius = 100,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      fillColor: Colors.white,
      icon: icon != null
          ? Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
    );
  }
}
