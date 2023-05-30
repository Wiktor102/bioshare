import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:bioshare/app/app_bar.dart';
import 'package:bioshare/common/app_background.dart';
import 'package:bioshare/common/expandable_list_view.dart';

class FridgeDetails extends StatelessWidget {
  final Function() goToLogin;
  final int length = 10;

  const FridgeDetails({required this.goToLogin, super.key});

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
                Card(
                  title: "Gdzie jestem?",
                  children: [
                    Image(
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                      image: const NetworkImage("https://picsum.photos/300/200"),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, left: 15, right: 15),
                        child: Text("Adres"),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        child: ElevatedButton.icon(
                          onPressed: () {},
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
                Card(
                  title: "Dostępne produkty",
                  children: [
                    ExpandableListView(
                      itemCount: length,
                      visibleItemCount: 3,
                      itemBuilder: (context, i) {
                        return ListTile(
                          title: Text("Jakaś rzecz $i"),
                          trailing: OutlinedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Biorę"),
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
                Card(
                  title: "Opis",
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, right: 10, bottom: 20),
                        child: Text(
                          "Administrator nie dodał opisu",
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

class Card extends StatelessWidget {
  final List<Widget> children;
  final String title;

  const Card({
    required this.children,
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 3),
            blurRadius: 5.0,
          ),
        ],
      ),
      child: Column(children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        ...children,
      ]),
    );
  }
}
