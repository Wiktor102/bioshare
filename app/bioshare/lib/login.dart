import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:provider/provider.dart';
import "common/custom_input_decoration.dart";
import "./utils/show_popup.dart";
import './models/location_model.dart';
import './utils/refresh_access_token.dart';

import './common/full_screen_loader.dart';
import './main.dart';

class LoginPage extends StatefulWidget {
  final Function() goToSignup;
  final Function() goToApp;
  const LoginPage(this.goToSignup, this.goToApp, {Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";

  @override
  void initState() {
    (() async {
      await refreshAccessToken(sessionExpire: false);
      String? accessToken = await App.secureStorage.read(key: "jwt");
      if (accessToken == null) return;

      Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/auth/verify_jwt.php");
      if (!kReleaseMode) {
        uri = Uri.parse("http://192.168.1.66:4000/auth/verify_jwt.php");
      }

      try {
        final http.Response response = await http.get(
          uri,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          },
        );

        if (response.statusCode == 200) {
          if (mounted) {
            Provider.of<LocationModel>(context, listen: false).askForPermission();
          }

          widget.goToApp();
        } else {
          // That means that the access token is somehow invalid and we can delete it
          await App.secureStorage.delete(key: "jwt");
        }
      } catch (e, s) {
        print(e);
        print(s);
      }
    })();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onFormSubmitted(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    _formKey.currentState!.save();

    if (email == "" || password == "") {
      showPopup(context, "Podaj dane logowania", null);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FullScreenLoader(),
      ),
    );

    Stopwatch stopwatch = Stopwatch()..start();
    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/auth/logIn.php");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/auth/logIn.php");
    }

    final String body = json.encode({
      "mail": email,
      "password": password,
    });

    List<String?> popupText = [null, null];

    try {
      final http.Response response = await http.post(uri, body: body);
      dynamic decodedResponse;

      if (response.body == "") {
        throw Exception(response.statusCode);
      }

      try {
        decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      } catch (e) {
        throw Exception(response.body);
      }

      if ([400, 500].contains(response.statusCode)) {
        throw Exception(response.statusCode);
      } else if (response.statusCode == 404) {
        popupText[0] = "Błędne dane logowania";
        popupText[1] = "Użytkownik o podanej kombinacji adresu e-mail i hasła nie istnieje.";
      } else if (response.statusCode != 200) {
        throw Exception(decodedResponse.error);
      } else {
        String accessToken = decodedResponse["accessToken"]["token"];
        String refreshToken = decodedResponse["refreshToken"];

        final Map<String, dynamic> decodedJWT = Jwt.parseJwt(accessToken);
        await App.secureStorage.write(key: "username", value: decodedJWT["preferred_username"]);
        await App.secureStorage.write(key: "email", value: decodedJWT["email"]);
        await App.secureStorage.write(key: "jwt", value: accessToken); // access token
        await App.secureStorage.write(key: "refreshToken", value: refreshToken);

        stopwatch.stop();
        if (stopwatch.elapsedMilliseconds < 2000) {
          await Future.delayed(Duration(milliseconds: 2000 - stopwatch.elapsedMilliseconds));
        }

        if (context.mounted) {
          Navigator.of(context).pop();
          Provider.of<LocationModel>(context, listen: false).askForPermission();
        }

        widget.goToApp();
        // print(decodedResponse["userId"]);
      }
    } catch (e, s) {
      popupText[0] = "Wystąpił nieznany błąd";
      popupText[1] = "Przepraszamy. Proszę spróbować później.";
      print(e);
      print(s);
    } finally {
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds < 2000) {
        await Future.delayed(Duration(milliseconds: 2000 - stopwatch.elapsedMilliseconds));
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 500)); // Długość animacji

        if (context.mounted && popupText[0] != null) {
          showPopup(context, popupText[0] ?? "", popupText[1]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              bottom: 350 - 40,
              height: MediaQuery.of(context).size.height - 350 + 40,
              width: MediaQuery.of(context).size.width,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    opacity: 0.3,
                    image: AssetImage('assets/fridgeBG.jpg'),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              height: 350,
              width: MediaQuery.of(context).size.width,
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(180 / 360),
                child: ClipPath(
                  clipper: Clipper(),
                  child: Container(
                    //   alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Zaloguj się',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                        child: Text(
                          'By korzystać z naszej aplikacji, musisz być zalogowany',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                            fontWeight: FontWeight.w300,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.1,
                        margin: const EdgeInsets.symmetric(vertical: 30),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  autofillHints: const [AutofillHints.email],
                                  onSaved: (v) => email = v ?? "",
                                  decoration: CustomInputDecoration(
                                    context,
                                    labelText: "Nazwa użytkownika lub e-mail",
                                    hintText: '',
                                    prefixIcon: Icons.person,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextFormField(
                                  autofillHints: const [AutofillHints.password],
                                  obscureText: true,
                                  obscuringCharacter: '*',
                                  onSaved: (v) => password = v ?? "",
                                  decoration: CustomInputDecoration(
                                    context,
                                    labelText: "Hasło",
                                    hintText: 'Wpisz swoje hasło',
                                    prefixIcon: Icons.lock,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                        ),
                                        onPressed: () => onFormSubmitted(context),
                                        child: const Text(
                                          'Kontynuuj',
                                          style: TextStyle(fontSize: 17),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nie masz jeszcze konta?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.goToSignup,
                            child: Text(
                              'Załóż je',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Clipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 4, size.height - 40, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 / 4 * size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(Clipper oldClipper) => false;
}
