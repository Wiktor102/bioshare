import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import './settings.dart';

// utilities
import '../utils/refresh_access_token.dart';
import '../utils/session_expired.dart';

// model classes / providers
import '../models/theme_model.dart';
import '../models/view_model.dart';

class CustomAppBar extends StatefulWidget {
  final String title;
  const CustomAppBar({required this.title, super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? username;
  String? email;

  @override
  initState() {
    Future.wait([
      App.secureStorage.read(key: "username"),
      App.secureStorage.read(key: "email"),
    ]).then((values) {
      if (mounted) {
        setState(() {
          username = values[0];
          email = values[1];
        });
      }
    });

    super.initState();
  }

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
                        image: AssetImage("assets/logoBaner50y.png"),
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
                      child: Selector<ThemeModel, Brightness>(
                        selector: (context, themeProvider) => themeProvider.brightness,
                        builder: (context, b, child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: b == Brightness.light ? Colors.white : Theme.of(context).primaryColorDark,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: child,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              ListTile(
                                leading: ProfilePicture(
                                  name: username!,
                                  radius: 20,
                                  fontsize: 22,
                                ),
                                title: Text(username!),
                                subtitle: Text(email!),
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
                                  onTap: () => goToSettings(context),
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

  goToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Settings()),
    );
  }

  logOut() async {
    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/auth/logOut.php?uid");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/auth/logOut.php");
    }

    String? jwt = await App.secureStorage.read(key: "jwt");

    if (jwt == null) {
      if (mounted) {
        sessionExpired(null);
      }

      return;
    }

    final http.Response response = await http.get(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $jwt',
      },
    );

    if (response.statusCode == 403) {
      await refreshAccessToken();
      logOut();
      return;
    }

    if (response.statusCode != 200) {
      print("Error! #${response.statusCode}: ${response.body}");
      sessionExpired(null);
      return;
    }

    await App.secureStorage.delete(key: "jwt");

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Provider.of<ViewModel>(context, listen: false).goToLogin();
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(widget.title),
      actions: [
        username != null
            ? IconButton(
                onPressed: () => showProfilePopup(context),
                icon: ProfilePicture(
                  name: username!,
                  radius: 13,
                  fontsize: 14,
                ),
              )
            : Container(),
      ],
      centerTitle: true,
    );
  }
}
