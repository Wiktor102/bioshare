import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

import './fridge_details.dart';
import '../common/app_background.dart';

class FridgesList extends StatelessWidget {
  final Function() goToLogin;
  const FridgesList({required this.goToLogin, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView.separated(
          itemCount: 10,
          itemBuilder: (context, index) => FridgeCard(goToLogin: goToLogin),
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
  const FridgeCard({required this.goToLogin, super.key});

  goToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FridgeDetails(
          goToLogin: goToLogin,
        ),
      ),
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
                  child: const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: ProfilePicture(
                          name: 'Barbara',
                          radius: 15,
                          fontsize: 16,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Nazwa"),
                            Text(
                              "10 km • ul. Kwiatowa",
                              style: TextStyle(color: Color.fromARGB(150, 0, 0, 0)),
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
              image: NetworkImage("https://picsum.photos/300"),
            )
          ],
        ),
      ),
    );
  }
}
