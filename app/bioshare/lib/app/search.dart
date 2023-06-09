import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import './fridges_list.dart';

// model classes / providers
import '../models/theme_model.dart';
import '../models/fridge_model.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final controller = TextEditingController();
  String query = "";
  ItemCategory? selectedCategory;
  bool shortExpire = false;
  bool loadingResults = false;
  List<Fridge> fridgesToShow = [];

  // Give the user time to stop typing -> ex. if query.length == 20, we don't want to make 20 http requests
  Timer? _debounce;

  onQueryChanged(BuildContext context, String newQuery) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    if (newQuery == "") {
      clearQuery();
      return;
    }

    setState(() {
      loadingResults = true;
      query = newQuery;
    });

    _debounce = Timer(const Duration(seconds: 1), () => search(context));
  }

  clearQuery() {
    setState(() {
      loadingResults = false;
      query = "";
      fridgesToShow = [];
    });

    controller.text = "";
  }

  search(BuildContext context) async {
    final provider = Provider.of<FridgeModel>(context, listen: false);
    final list = await provider.search(query, selectedCategory, shortExpire);
    fridgesToShow = list.map((Fridge f) => f.id).map((id) => provider.getFridge(id)).whereType<Fridge>().toList();

    setState(() {
      loadingResults = false;
    });
  }

  searchOrClear() {
    if (query.isNotEmpty || selectedCategory != null || shortExpire) {
      search(context);
    } else {
      clearQuery();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Selector<ThemeModel, Brightness>(
            selector: (context, themeProvider) => themeProvider.brightness,
            builder: (context, b, child) {
              return TextFormField(
                controller: controller,
                onChanged: (q) => onQueryChanged(context, q),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                textInputAction: TextInputAction.search,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: clearQuery,
                        )
                      : null,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  labelText: "Szukaj",
                  hintText: "Nazwa lodówki, produkt",
                  filled: true,
                  fillColor: b == Brightness.light
                      ? Theme.of(context).primaryColorLight
                      : Theme.of(context).primaryColorDark,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(90.0)),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 16),
                SizedBox(width: 5),
                Text("Filtry"),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              itemCount: ItemCategory.values.length + 1,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return FilterChip(
                    label: const Text("Krótka ważność"),
                    showCheckmark: false,
                    avatar: null,
                    selected: shortExpire,
                    onSelected: (bool selected) {
                      setState(() {
                        shortExpire = selected;
                      });

                      searchOrClear();
                    },
                  );
                }

                ItemCategory currCat = ItemCategory.values[i - 1];
                return FilterChip(
                  label: Text(currCat.toString()),
                  showCheckmark: false,
                  selected: selectedCategory == currCat,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedCategory = selected ? currCat : null;
                    });

                    searchOrClear();
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 10),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: fridgesToShow.isNotEmpty && !loadingResults
                ? FridgesList(fridges: fridgesToShow, background: false)
                : Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Selector<ThemeModel, Brightness>(
                              selector: (context, themeProvider) => themeProvider.brightness,
                              builder: (context, b, child) {
                                return Image(
                                  image: AssetImage(b == Brightness.light
                                      ? "assets/fridgeSearch.png"
                                      : "assets/fridgeSearchLight.png"),
                                );
                              }),
                          const SizedBox(height: 10),
                          loadingResults
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      "Ładowanie...",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                )
                              : Text(
                                  query.isEmpty && selectedCategory == null
                                      ? "Wpisz szukaną frazę lub wybierz kategorię"
                                      : "Nie znaleziono tego czego szukasz",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18),
                                ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
