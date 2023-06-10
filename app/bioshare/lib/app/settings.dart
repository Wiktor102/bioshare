import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:bioshare/app/app_bar.dart';

// model classes / providers
import 'package:bioshare/models/theme_model.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: CustomAppBar(
          title: "Ustawienia",
        ),
      ),
      body: ListView(
        children: const [
          ThemeTile(),
          Divider(),
          AboutApp(),
        ],
      ),
    );
  }
}

class ThemeTile extends StatelessWidget {
  const ThemeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Motyw"),
      leading: const Icon(Icons.brightness_4),
      trailing: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.4,
        ),
        child: Consumer<ThemeModel>(builder: (context, themeProvider, child) {
          return DropdownButton<AppTheme>(
            value: themeProvider.theme,
            onChanged: (nt) => themeProvider.theme = nt ?? AppTheme.auto,
            items: const [
              DropdownMenuItem(
                value: AppTheme.auto,
                child: Text("Automatyczny"),
              ),
              DropdownMenuItem(
                value: AppTheme.light,
                child: Text("Jasny"),
              ),
              DropdownMenuItem(
                value: AppTheme.dark,
                child: Text("Ciemny"),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class AboutApp extends StatefulWidget {
  const AboutApp({super.key});

  @override
  State<AboutApp> createState() => _AboutAppState();
}

class _AboutAppState extends State<AboutApp> {
  String? version;
  String? buildNumber;

  @override
  void initState() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        version = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    });
    super.initState();
  }

  TextStyle textStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text("O aplikacji"),
        leading: const Icon(Icons.info),
        childrenPadding: const EdgeInsets.only(left: 24),
        children: [
          ListTile(
            title: const Text("Autor"),
            leading: const Icon(Icons.badge),
            trailing: Text("Wiktor Golicz", style: textStyle),
          ),
          ExpansionTile(
            title: const Text("Opis"),
            leading: const Icon(Icons.description),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0, left: 15, right: 25),
                child: Text(
                  "Bio-Share to aplikacja mobinla na sysytem Android. Celem aplikacji jest przeciwdziałanie zmianom klmiatu poprzez ograniczenie marnowania żywności. Aplikacja jest narzędziem do zarządzania lodówkami publicznymi (miejscami do dzielenia się żywnością). W obecnym stanie aplikacja jest działającym prototypem.\n\nAplikacja Bio-Share pozwala zarządzać zawartością lodówek. Jeśli lodówki do dzielenia się żywnością staną się popularne to będzie to miało realny wpływ na zmniejszenie produkcji żywności, a to ona wpływa w dużym stopniu na produkcje gazów cieplarnianych.",
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.85)),
                ),
              )
            ],
          ),
          const ExpansionTile(
            title: Text("Źródła grafik"),
            leading: Icon(Icons.source),
            childrenPadding: EdgeInsets.only(left: 59),
            children: [
              ListTile(title: Text("undraw.co")),
              ListTile(title: Text("unsplash.com")),
              ListTile(title: Text("twórczość własna")),
            ],
          ),
          ListTile(
            title: const Text("Wersja"),
            trailing: version == null ? const CircularProgressIndicator() : Text("v $version", style: textStyle),
          ),
          ListTile(
            title: const Text("Nr kompilacji"),
            trailing:
                buildNumber == null ? const CircularProgressIndicator() : Text(buildNumber!, style: textStyle),
          )
        ],
      ),
    );
  }
}
