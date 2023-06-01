import 'package:bioshare/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fridge_model.dart';
import './app_bar.dart';
import '../common/app_background.dart';
import '../common/expandable_list_view.dart';

class FridgeDetails extends StatelessWidget {
  final Function() goToLogin;
  final Fridge fridge;
  final int length = 10;

  const FridgeDetails({
    required this.fridge,
    required this.goToLogin,
    super.key,
  });

  directions() async {
    final availableMaps = await MapLauncher.installedMaps;
    await availableMaps.first.showMarker(
      coords: Coords(fridge.location.latitude, fridge.location.longitude),
      title: fridge.name,
    );
  }

  showItemOptions(BuildContext context, Item item) {
    showBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text("Tego produktu już tu nie ma"),
              subtitle: Text("Usuń go"),
              leading: Icon(Icons.delete),
            ),
            const ListTile(
              title: Text("Edytuj"),
              leading: Icon(Icons.edit),
            ),
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

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: CustomAppBar(
            title: "Szczegóły",
            goToLogin: () {
              Navigator.of(context).pop();
              goToLogin();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 20 + 56 + 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomCard(
                  title: "Gdzie jestem?",
                  children: [
                    SizedBox(
                      height: 170,
                      child: FlutterMap(
                        options: MapOptions(
                          center: fridge.location,
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
                                point: fridge.location,
                                width: 35,
                                height: 35,
                                builder: (context) => const Image(image: AssetImage("assets/pinBlue.png")),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    fridge.address != null
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
                              child: Text(fridge.address ?? ""),
                            ),
                          )
                        : Container(),
                    fridge.test
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
                        child: ElevatedButton.icon(
                          onPressed: directions,
                          icon: const Icon(Icons.directions),
                          label: const Text("Prowadź"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomCard(
                  title: "Dostępne produkty",
                  children: [
                    ExpandableListView(
                      itemCount: fridge.availableItems.length,
                      visibleItemCount: 3,
                      itemBuilder: (context, i) {
                        final Item item = fridge.availableItems[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 20, right: 0),
                          title: Text(item.name),
                          trailing: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Biorę"),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => showItemOptions(context, item),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => Divider(
                        color: Theme.of(context).primaryColorLight,
                        thickness: 1.0,
                        height: 0.0,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                CustomCard(
                  title: "Opis",
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, right: 10, bottom: 20),
                        child: Text(
                          fridge.description ?? "Administrator nie dodał opisu",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black.withAlpha(160),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          label: const Text("Podziel się"),
          icon: const Icon(Icons.add),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
