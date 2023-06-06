import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import './fridge_details.dart';
import '../utils/calc_distance.dart';
import '../common/app_background.dart';
import '../models/fridge_model.dart';

enum FridgeListType { normal, admin }

class FridgesList extends StatelessWidget {
  final List<Fridge> fridges;
  final FridgeListType listType;

  const FridgesList({
    required this.fridges,
    this.listType = FridgeListType.normal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView.separated(
          itemCount: fridges.length,
          itemBuilder: (context, i) => FridgeCard(fridge: fridges[i], tileType: listType),
          separatorBuilder: (context, index) => const SizedBox(
            height: 10,
          ),
        ),
      ),
    );
  }
}

class FridgeCard extends StatelessWidget {
  final Fridge fridge;
  final FridgeListType tileType;

  const FridgeCard({
    required this.fridge,
    required this.tileType,
    super.key,
  });

  goToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FridgeDetails(
          fridge: fridge,
          provider: Provider.of<FridgeModel>(context),
          type: tileType == FridgeListType.normal ? FridgeDetailsType.normal : FridgeDetailsType.admin,
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
    Color? color;
    final numberOfExpiredItems = fridge.getExpiredItems();

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
          style: const TextStyle(color: Color.fromARGB(150, 0, 0, 0)),
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
          color: Theme.of(context).secondaryHeaderColor,
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
