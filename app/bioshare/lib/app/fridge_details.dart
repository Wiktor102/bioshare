import 'package:bioshare/app/add_product.dart';
import 'package:bioshare/common/conditional_parent_widget.dart';
import 'package:bioshare/common/custom_card.dart';
import 'package:bioshare/models/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fridge_model.dart';
import './app_bar.dart';
import '../common/app_background.dart';
import '../common/expandable_list_view.dart';

enum FridgeDetailsType { normal, admin }

class FridgeDetails extends StatefulWidget {
  final Fridge fridge;
  final FridgeModel provider;
  final FridgeDetailsType type;

  const FridgeDetails({
    required this.fridge,
    required this.provider,
    this.type = FridgeDetailsType.normal,
    super.key,
  });

  @override
  State<FridgeDetails> createState() => _FridgeDetailsState();
}

class _FridgeDetailsState extends State<FridgeDetails> {
  Future<void>? itemsFetchFuture;
  String? editedDescription;
  bool editDescriptionMode = false;
  late DateTime lastUpdatedItems;

  _getButtonStyle(BuildContext context) {
    final b = Provider.of<ThemeModel>(context).brightness;
    return ElevatedButton.styleFrom(
      backgroundColor: b == Brightness.light
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.inversePrimary,
      foregroundColor: Colors.white,
    );
  }

  @override
  initState() {
    lastUpdatedItems = widget.fridge.lastUpdatedItems ?? DateTime.now();
    final timePassed = DateTime.now().difference(lastUpdatedItems) >= const Duration(minutes: 30);

    if (widget.fridge.availableItems == null || timePassed) {
      itemsFetchFuture = widget.provider.fetchFridgeItems(widget.fridge.id);
    }
    super.initState();
  }

  void directions() async {
    final availableMaps = await MapLauncher.installedMaps;
    await availableMaps.first.showMarker(
      coords: Coords(widget.fridge.location.latitude, widget.fridge.location.longitude),
      title: widget.fridge.name,
    );
  }

  void showItemOptions(BuildContext context, Item item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                deleteProduct(context, null, item.id);
                Navigator.of(context).pop();
              },
              child: const ListTile(
                title: Text("Tego produktu już tu nie ma"),
                subtitle: Text("Usuń go"),
                leading: Icon(Icons.delete),
              ),
            ),
            item.amount != null
                ? InkWell(
                    onTap: () => editProductAmount(context, item),
                    child: const ListTile(
                      title: Text("Edytuj ilość"),
                      leading: Icon(Icons.edit),
                    ),
                  )
                : Container(),
            InkWell(
              onTap: () => editProductExpireDate(context, item),
              child: ListTile(
                title: Text(item.expire != null ? "Edytuj datę ważności" : "Dodaj datę ważności"),
                leading: Icon(item.expire != null ? Icons.edit_calendar : Icons.event),
              ),
            ),
            item.expire != null
                ? InkWell(
                    onTap: () => deleteProductExpireDate(context, item),
                    child: const ListTile(
                      title: Text("Usuń datę ważności"),
                      leading: Icon(Icons.event_busy),
                    ),
                  )
                : Container(),
            ListTile(
              title: const Text("Zamknij"),
              leading: const Icon(Icons.close),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void addProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProduct(fridgeId: widget.fridge.id),
      ),
    );
  }

  Future<void> takeProduct(BuildContext context, int i) async {
    final provider = Provider.of<FridgeModel>(context, listen: false);
    final item = widget.fridge.availableItems![i];

    if (item.amount == null) {
      deleteProduct(context, i, null);
      return;
    }

    GlobalKey<FormState> fk = GlobalKey<FormState>();
    double takeAmount = 1;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Wybierz ilość"),
        content: Form(
          key: fk,
          child: TextFormField(
            autofocus: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            validator: (String? value) {
              if (value == null) return null;
              if (double.tryParse(value) == null || double.parse(value) <= 0) return "Niepoprawna wartość";
              if (double.parse(value) < 0 || double.parse(value) > item.amount!) {
                return "Zakres 0 - ${item.amount! % 1 == 0 ? item.amount!.toInt() : item.amount}";
              }

              return null;
            },
            onSaved: (v) {
              takeAmount = double.parse(v!);
            },
          ),
        ),
        actions: [
          Row(
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Anuluj")),
              TextButton(
                onPressed: () {
                  deleteProduct(context, i, null);
                  Navigator.of(context).pop();
                },
                child: const Text("Biorę wszystko"),
              ),
              TextButton(
                onPressed: () {
                  if (!fk.currentState!.validate()) return;
                  fk.currentState!.save();
                  Navigator.of(context).pop();
                },
                child: const Text("Ok"),
              ),
            ],
          ),
        ],
      ),
    );

    provider.setItemAmount(widget.fridge.id, item.id, item.amount! - takeAmount);
  }

  void deleteProduct(BuildContext context, int? i, int? itemId) {
    final provider = Provider.of<FridgeModel>(context, listen: false);
    itemId ??= widget.fridge.availableItems![i!].id;
    provider.deleteItem(widget.fridge.id, itemId);
  }

  void editProductExpireDate(BuildContext context, Item item) async {
    Navigator.of(context).pop();
    final provider = Provider.of<FridgeModel>(context, listen: false);
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: item.expire ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
        locale: const Locale("pl", "PL"));

    if (picked == null || picked == item.expire) {
      return;
    }

    provider.setItemExpire(widget.fridge.id, item.id, picked);
  }

  void deleteProductExpireDate(BuildContext context, Item item) async {
    Navigator.of(context).pop();
    final provider = Provider.of<FridgeModel>(context, listen: false);
    provider.setItemExpire(widget.fridge.id, item.id, null);
  }

  void editProductAmount(BuildContext context, Item item) async {
    Navigator.of(context).pop();
    final provider = Provider.of<FridgeModel>(context, listen: false);
    double? newAmount = await showDialog<double>(
      context: context,
      builder: (context) => const DoubleDialog(dialog: "Podaj nową ilość"),
    );

    if (newAmount == null) return;
    provider.setItemAmount(widget.fridge.id, item.id, newAmount);
  }

// Unused:
  void deleteProductAmount(BuildContext context, Item item) async {
    Navigator.of(context).pop();
    final provider = Provider.of<FridgeModel>(context, listen: false);
    provider.setItemAmount(widget.fridge.id, item.id, null);
  }

  void toggleEditDescriptionMode() {
    if (widget.type == FridgeDetailsType.normal) return;
    setState(() {
      editDescriptionMode = !editDescriptionMode;
    });
  }

  void submitDescriptionChange() {
    if (editedDescription == null || editedDescription == widget.fridge.description) {
      discardDescriptionChange();
      return;
    }

    widget.provider
        .editFridgeDescription(widget.fridge.id, editedDescription!)
        .then((value) => discardDescriptionChange());
  }

  void discardDescriptionChange() {
    editedDescription = null;
    toggleEditDescriptionMode();
  }

  void deleteFridge(BuildContext context) async {
    if (widget.type == FridgeDetailsType.normal) return;
    bool result = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Czy na pewno chcesz usunąć tą lodówkę?"),
        content: const Text(
            "Razem z lodówką zostaną usunięte także wszystkie znajdujące się w niej rzeczy. Ta operacja nie może być cofnięta."),
        actions: [
          TextButton(
            onPressed: () {
              result = false;
              Navigator.of(context).pop();
            },
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () {
              result = true;
              Navigator.of(context).pop();
            },
            child: const Text("Usuń"),
          )
        ],
      ),
    );

    if (!result) {
      return;
    }

    if (context.mounted) {
      final provider = Provider.of<FridgeModel>(context, listen: false);
      bool success = await provider.deleteFridge(widget.fridge.id);
      if (success && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> refreshItems(BuildContext context) async {
    final timePassed = DateTime.now().difference(lastUpdatedItems) >= const Duration(minutes: 1);
    if (!timePassed) return;

    setState(() {
      itemsFetchFuture = widget.provider.fetchFridgeItems(widget.fridge.id);
      widget.fridge.availableItems = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: CustomAppBar(
              title: widget.type == FridgeDetailsType.normal ? "Szczegóły" : "Zarządzaj",
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => refreshItems(context),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 20 + 56 + 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    widget.type == FridgeDetailsType.normal
                        ? CustomCard(
                            title: "Gdzie jestem?",
                            children: [
                              SizedBox(
                                height: 170,
                                child: FlutterMap(
                                  options: MapOptions(
                                    center: widget.fridge.location,
                                    zoom: 15,
                                    minZoom: 6,
                                    maxZoom: 17,
                                  ),
                                  nonRotatedChildren: [
                                    RichAttributionWidget(
                                      showFlutterMapAttribution: false,
                                      attributions: [
                                        TextSourceAttribution(
                                          'OpenStreetMap contributors',
                                          onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                                        ),
                                      ],
                                    ),
                                  ],
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.example.app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: widget.fridge.location,
                                          width: 35,
                                          height: 35,
                                          builder: (context) =>
                                              const Image(image: AssetImage("assets/pinBlue.png")),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              widget.fridge.address != null
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
                                        child: Text(widget.fridge.address ?? ""),
                                      ),
                                    )
                                  : Container(),
                              widget.fridge.test
                                  ? Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Container(
                                        width: MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                                        margin: const EdgeInsets.only(top: 10, left: 15, right: 15),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withAlpha(160),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.warning, size: 20),
                                                SizedBox(width: 15),
                                                Text(
                                                  "Lodówka nie istnieje",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                "Ta lodówka została stworzona wyłącznie na potrzeby testów aplikacji. Nie istnieje w rzeczywistości.",
                                                style: TextStyle(color: Colors.black.withAlpha(130)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  child: Selector<ThemeModel, Brightness>(
                                      selector: (context, themeProvider) => themeProvider.brightness,
                                      builder: (context, b, child) {
                                        return ElevatedButton.icon(
                                          onPressed: directions,
                                          icon: const Icon(Icons.directions),
                                          label: const Text("Prowadź"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: b == Brightness.light
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.inversePrimary,
                                            foregroundColor: Colors.white,
                                          ),
                                        );
                                      }),
                                ),
                              ),
                            ],
                          )
                        : Container(),
                    widget.type == FridgeDetailsType.normal ? const SizedBox(height: 20) : Container(),
                    CustomCard(
                      title: "Dostępne produkty",
                      children: [
                        ConditionalParentWidget(
                          condition: itemsFetchFuture != null,
                          conditionalBuilder: (Widget child) => FutureBuilder(
                            future: itemsFetchFuture,
                            builder: (context, AsyncSnapshot<void> snapshot) =>
                                snapshot.connectionState == ConnectionState.waiting
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 20),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : child,
                          ),
                          child: !(widget.fridge.availableItems == null || widget.fridge.availableItems!.isEmpty)
                              ? ExpandableListView(
                                  itemCount: widget.fridge.availableItems!.length,
                                  visibleItemCount: widget.fridge.availableItems!.length < 3
                                      ? widget.fridge.availableItems!.length
                                      : widget.type == FridgeDetailsType.admin
                                          ? widget.fridge.availableItems!.length
                                          : 3,
                                  itemBuilder: (context, i) {
                                    final Item item = widget.fridge.availableItems![i];
                                    final DateTime now = DateUtils.dateOnly(DateTime.now());
                                    final bool? isSameMoment = item.expire?.isAtSameMomentAs(now);
                                    final bool? isBefore = item.expire?.isBefore(now);
                                    final bool expired = item.expire != null && (isBefore! && !isSameMoment!);
                                    return SizedBox(
                                      height: 70,
                                      child: Center(
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 20, right: 0),
                                          title: item.amount != null
                                              ? Text(
                                                  "${item.name} - ${item.amount! % 1 == 0 ? item.amount!.toInt() : item.amount} ${item.unit}")
                                              : Text(item.name),
                                          subtitle: item.expire == null
                                              ? null
                                              : !expired
                                                  ? Text(
                                                      "Ważne do: ${DateFormat('dd.MM.yyyy').format(item.expire!)}")
                                                  : const Text("Data ważności minęła",
                                                      style: TextStyle(color: Colors.red)),
                                          trailing: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              (item.expire == null || !expired) &&
                                                      widget.type != FridgeDetailsType.admin
                                                  ? ElevatedButton(
                                                      onPressed: () => takeProduct(context, i),
                                                      style: _getButtonStyle(context),
                                                      child: const Text("Biorę"),
                                                    )
                                                  : ElevatedButton(
                                                      onPressed: () => deleteProduct(context, i, null),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xffcb2d22),
                                                        foregroundColor: Colors.white,
                                                      ),
                                                      child: const Text("Usuń"),
                                                    ),
                                              IconButton(
                                                icon: const Icon(Icons.more_vert),
                                                onPressed: () => showItemOptions(context, item),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  separatorBuilder: (context, index) => Divider(
                                    color: Theme.of(context).primaryColorLight,
                                    thickness: 1.0,
                                    height: 0.0,
                                  ),
                                )
                              : Empty(addProduct),
                        ),
                        widget.type == FridgeDetailsType.admin && widget.fridge.availableItems!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ElevatedButton.icon(
                                  onPressed: () => addProduct(context),
                                  style: _getButtonStyle(context),
                                  label: const Text("Dodaj produkt"),
                                  icon: const Icon(Icons.add),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomCard(
                      title: "Opis",
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 15,
                                  right: 10,
                                  bottom: widget.type == FridgeDetailsType.admin && !editDescriptionMode ? 45 : 20,
                                ),
                                child: editDescriptionMode
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          TextFormField(
                                            initialValue: widget.fridge.description,
                                            onChanged: (newValue) => editedDescription = (newValue),
                                            autovalidateMode: AutovalidateMode.onUserInteraction,
                                            validator: (value) {
                                              if ((value?.length ?? 0) > 1000) {
                                                return "Max. 1000 znaków";
                                              }

                                              return null;
                                            },
                                            maxLines: null,
                                            decoration: InputDecoration(
                                              labelText: "Edytuj opis",
                                              hintText: "Nie dodano jeszcze opisu",
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: submitDescriptionChange,
                                                  style: _getButtonStyle(context),
                                                  child: const Icon(Icons.done),
                                                ),
                                                const SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: discardDescriptionChange,
                                                  style: _getButtonStyle(context),
                                                  child: const Icon(Icons.close),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      )
                                    : Text(
                                        widget.fridge.description != null && widget.fridge.description != ""
                                            ? widget.fridge.description!
                                            : (widget.type == FridgeDetailsType.normal
                                                ? "Administrator nie dodał opisu"
                                                : "Nie dodano jeszcze opisu"),
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.85),
                                        ),
                                      ),
                              ),
                              widget.type == FridgeDetailsType.admin && !editDescriptionMode
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: IconButton(
                                        onPressed: toggleEditDescriptionMode,
                                        icon: const Icon(Icons.edit),
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: widget.type == FridgeDetailsType.normal
              ? FloatingActionButton.extended(
                  onPressed: () => addProduct(context),
                  label: const Text("Podziel się"),
                  icon: const Icon(Icons.add),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                )
              : FloatingActionButton(
                  onPressed: () => deleteFridge(context),
                  backgroundColor: const Color.fromARGB(255, 202, 45, 34),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.delete_forever_outlined),
                ),
        ),
      ),
    );
  }
}

class Empty extends StatelessWidget {
  final Function(BuildContext) addProduct;
  const Empty(this.addProduct, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 50, right: 50, bottom: 20, top: 20),
            child: Image(image: AssetImage("assets/empty.png")),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text("Lodówka jest pusta", style: TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton.icon(
              onPressed: () => addProduct(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              label: const Text("Dodaj produkt"),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class DoubleDialog extends StatefulWidget {
  final String dialog;

  const DoubleDialog({
    required this.dialog,
    super.key,
  });

  @override
  State<DoubleDialog> createState() => _DoubleDialogState();
}

class _DoubleDialogState extends State<DoubleDialog> {
  final controller = TextEditingController();
  bool valid = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialog),
      content: TextFormField(
        controller: controller,
        autofocus: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        validator: (String? value) {
          if (value == null) return null;
          if (double.tryParse(value) == null || double.parse(value) <= 0) return "Niepoprawna wartość";
          return null;
        },
        onChanged: (v) {
          setState(() {
            valid = !(double.tryParse(v) == null || double.parse(v) <= 0);
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.clear();
            Navigator.of(context).pop(null);
          },
          child: const Text("Anuluj"),
        ),
        TextButton(
          onPressed: valid
              ? () {
                  Navigator.of(context).pop(double.parse(controller.text));
                }
              : null,
          child: const Text("Potwierdź"),
        ),
      ],
    );
  }
}
