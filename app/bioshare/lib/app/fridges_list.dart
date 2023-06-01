import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import './fridge_details.dart';
import '../utils/calc_distance.dart';
import '../common/app_background.dart';
import '../models/fridge_model.dart';

class FridgesList extends StatelessWidget {
  final Function() goToLogin;
  final List<Fridge> fridges;

  const FridgesList({
    required this.goToLogin,
    required this.fridges,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView.separated(
          itemCount: fridges.length,
          itemBuilder: (context, i) => FridgeCard(
            goToLogin: goToLogin,
            fridge: fridges[i],
          ),
          separatorBuilder: (context, index) => const SizedBox(
            height: 10,
          ),
        ),
      ),
    );
  }
}

class FridgeCard extends StatelessWidget {
  final Function() goToLogin;
  final Fridge fridge;

  const FridgeCard({required this.goToLogin, required this.fridge, super.key});

  goToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FridgeDetails(
          fridge: fridge,
          goToLogin: goToLogin,
        ),
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
                            Text(fridge.name),
                            Consumer<LocationModel>(
                              builder: cardSubtitleBuilder,
                            ),
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
