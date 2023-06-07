import 'package:bioshare/app/fridges_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// model classes
import '../models/fridge_model.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final controller = TextEditingController();
  String query = "";
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

    _debounce = Timer(const Duration(seconds: 1), () async {
      final provider = Provider.of<FridgeModel>(context, listen: false);
      final list = await provider.search(query);
      fridgesToShow =
          list.map((Fridge f) => f.id).map((id) => provider.getFridge(id)).whereType<Fridge>().toList();

      setState(() {
        loadingResults = false;
      });
    });
  }

  clearQuery() {
    setState(() {
      loadingResults = false;
      query = "";
      fridgesToShow = [];
    });

    controller.text = "";
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
          TextFormField(
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
              hintText: "Nazwa lodówki lub produkt",
              filled: true,
              fillColor: Theme.of(context).primaryColorLight,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(90.0)),
                borderSide: BorderSide.none,
              ),
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
                          const Image(image: AssetImage("assets/fridgeSearch.png")),
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
                                  query.isEmpty ? "Wpisz szukaną frazę" : "Nie znaleziono tego czego szukasz",
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
