import 'package:bioshare/models/view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class CustomAppBar extends StatefulWidget {
  final String title;
  const CustomAppBar({required this.title, super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  showProfilePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          actionsPadding: const EdgeInsets.all(0),
          iconPadding: const EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                height: 58,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Align(
                      child: Image(
                        height: 30,
                        image: NetworkImage("https://logoipsum.com/logoipsum.png"),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              const ListTile(
                                leading: ProfilePicture(
                                  name: 'Wiktor',
                                  radius: 20,
                                  fontsize: 22,
                                ),
                                title: Text("Wiktor Golicz"),
                                subtitle: Text("wiktorgolicz@gmail.com"),
                              ),
                              Container(
                                height: 3,
                                color: Theme.of(context).secondaryHeaderColor,
                              ),
                              Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  title: const Text("Ustawienia"),
                                  leading: const Icon(Icons.settings),
                                  onTap: () {},
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  title: const Text("Wyloguj się"),
                                  leading: const Icon(Icons.logout),
                                  onTap: logOut,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  logOut() async {
    await App.secureStorage.delete(key: "jwt");

    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/auth/logOut.php");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/auth/logOut.php");
    }

    final http.Response response = await http.get(uri);

    if (response.statusCode == 200) {
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Provider.of<ViewModel>(context, listen: false).goToLogin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(widget.title),
      actions: [
        IconButton(
          onPressed: () => showProfilePopup(context),
          icon: const ProfilePicture(
            name: 'Wiktor',
            radius: 13,
            fontsize: 14,
          ),
        ),
      ],
      centerTitle: true,
    );
  }
}
