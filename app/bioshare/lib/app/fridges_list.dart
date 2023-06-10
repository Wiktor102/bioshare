import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../common/conditional_parent_widget.dart';
import '../models/location_model.dart';
import './fridge_details.dart';
import '../utils/calc_distance.dart';
import '../common/app_background.dart';
import '../models/fridge_model.dart';

enum FridgeListType { normal, admin, search }

class FridgesList extends StatefulWidget {
  final List<Fridge> fridges;
  final FridgeListType listType;
  final bool background;
  final Map<int, int>? p;
  const FridgesList({
    required this.fridges,
    this.listType = FridgeListType.normal,
    this.background = true,
    this.p, // matchingResultsMap -> Why p? Idk, don't ask. Just deal with it
    super.key,
  });

  @override
  State<FridgesList> createState() => _FridgesListState();
}

class _FridgesListState extends State<FridgesList> {
  List<Fridge>? sortedFridges;

  @override
  void initState() {
    final locationProvider = Provider.of<LocationModel>(context, listen: false).location;
    locationProvider.then((userLocation) {
      sortedFridges = [...widget.fridges];
      if (userLocation == null) return;

      sortedFridges!.sort((a, b) {
        int distanceA = calculateDistance(
          a.location.latitude,
          a.location.longitude,
          userLocation.latitude,
          userLocation.longitude,
        ).toInt();

        int distanceB = calculateDistance(
          b.location.latitude,
          b.location.longitude,
          userLocation.latitude,
          userLocation.longitude,
        ).toInt();

        return distanceA - distanceB;
      });

      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParentWidget(
      condition: widget.background,
      conditionalBuilder: (child) => AppBackground(child: child),
      child: sortedFridges != null
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: ListView.separated(
                itemCount: sortedFridges!.length,
                itemBuilder: (context, i) => FridgeCard(
                  fridge: sortedFridges![i],
                  tileType: widget.listType,
                  p: widget.p?[sortedFridges![i].id],
                ),
                separatorBuilder: (context, index) => const SizedBox(
                  height: 10,
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class FridgeCard extends StatelessWidget {
  final Fridge fridge;
  final FridgeListType tileType;
  final int? p;

  const FridgeCard({
    required this.fridge,
    required this.tileType,
    this.p,
    super.key,
  });

  goToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FridgeDetails(
          fridge: fridge,
          provider: Provider.of<FridgeModel>(context),
          type: tileType == FridgeListType.admin ? FridgeDetailsType.admin : FridgeDetailsType.normal,
        ),
      ),
    );
  }

  Widget getSubtitle(BuildContext context) {
    if (tileType == FridgeListType.normal) {
      return Consumer<LocationModel>(
        builder: cardSubtitleBuilder,
      );
    }

    final timePassed =
        DateTime.now().difference(fridge.lastUpdatedItems ?? DateTime.now()) >= const Duration(minutes: 30);

    if (fridge.availableItems == null || timePassed) {
      final provider = Provider.of<FridgeModel>(context);
      provider.fetchFridgeItems(fridge.id);
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    late String message;
    late IconData icon;
    Color color = Theme.of(context).colorScheme.onPrimaryContainer;
    final numberOfExpiredItems = fridge.getExpiredItems();

    if (tileType == FridgeListType.admin) {
      if (fridge.availableItems!.isNotEmpty) {
        message = "Liczba produktów: ${fridge.availableItems!.length}";
        icon = Icons.info;
      }

      if (fridge.availableItems!.isEmpty) {
        message = "Lodówka jest pusta";
        icon = Icons.hide_source;
        color = Colors.orange;
      }

      if (numberOfExpiredItems > 0) {
        message = "Przeterminowan${numberOfExpiredItems > 1 ? "e produkty" : "y produkt"}";
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
      }
    }

    if (tileType == FridgeListType.search) {
      // Polski jezyk trudny byc
      int lastDigit = p! % 10;
      bool isCase1 = [1, 2, 3, 4].contains(lastDigit);
      message = p == 1 ? 'Znaleziono 1 produkt' : 'Znaleziono $p produkt${isCase1 ? "y" : "ów"}';
      icon = Icons.search;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(message, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget cardSubtitleBuilder(BuildContext context, LocationModel locationProvider, Widget? child) {
    final Future<Position?> userLocationFuture = locationProvider.location;

    return FutureBuilder(
      future: userLocationFuture,
      builder: (context, AsyncSnapshot<Position?> snapshot) {
        final Position? userLocation = snapshot.data;
        final String? address = fridge.address;
        int? distance;
        String output = "";

        if (userLocation != null) {
          distance = calculateDistance(
            fridge.location.latitude,
            fridge.location.longitude,
            userLocation.latitude,
            userLocation.longitude,
          ).toInt();
        }

        if (address == null && userLocation == null) {
          return Container();
        }

        if (address != null) {
          output = address;
        }

        if (distance != null) {
          output = "$distance km";
        }

        if (address != null && distance != null) {
          output = "$distance km • ul. $address";
        }

        return Text(
          output,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.85),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => goToDetails(context),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: ProfilePicture(
                          name: fridge.adminUsername,
                          radius: 15,
                          fontsize: 16,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              fridge.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            getSubtitle(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Image(
              image: AssetImage("assets/fridge_placeholder.png"),
            )
          ],
        ),
      ),
    );
  }
}
