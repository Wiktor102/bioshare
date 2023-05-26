import 'dart:convert';

import 'package:flutter/material.dart';
import "common/custom_input_decoration.dart";
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SignupPage extends StatefulWidget {
  final Function() goToLogin;
  const SignupPage(this.goToLogin, {Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String email = "";
  String password = "";
  String password2 = "";

  String? emailError;
  String? passwordError;
  String? password2Error;

  bool loading = false;

  @override
  void dispose() {
    _textEditingController.clear();
    super.dispose();
  }

  void onFormSubmitted(BuildContext context) async {
    setState(() {
      loading = true;
    });

    _formKey.currentState!.save();
    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/auth/signUp.php");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/auth/signUp.php");
    }

    final String body = json.encode({
      "mail": email,
      "password": password,
      "password2": password2,
      "terms": true, // akceptacja regulaminu
      "privacy": true // akceptacja polityki prywatności
    });

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

      if (response.statusCode == 400) {
        setState(() {
          for (var error in decodedResponse["errors"]) {
            switch (error["type"]) {
              case "mail":
                if (emailError != null) break;
                emailError = error["error"];
                break;
              case "password":
                if (passwordError != null) break;
                passwordError = error["error"];
                break;
              case "password2":
                if (password2Error != null) break;
                password2Error = error["error"];
                break;
              default:
            }
          }
        });
      }

      if (response.statusCode == 409) {
        if (!context.mounted) return;
        _showPopup(context, "Wystąpił błąd", "Użytkownik o podanym adresie e-mail już istnieje.");
        return;
      }

      if (response.statusCode != 200) {
        throw Exception(decodedResponse.error);
      }

      print(decodedResponse["userId"]);

      widget.goToLogin();
      if (!context.mounted) return;
      _showPopup(context, "Rejestracja pomyślna", "Teraz możesz sie zalogować.");
    } catch (e) {
      _showPopup(context, "Wystąpił nieznany błąd", "Przepraszamy. Proszę spróbować później.");
    }

    validateForm();
    setState(() {
      loading = false;
    });
  }

  void _showPopup(BuildContext context, String title, String? content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content == null ? null : Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  validateForm() => _formKey.currentState!.validate();

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
                    decoration: BoxDecoration(color: Theme.of(context).primaryColorLight),
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
                        'Rejestracja',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _textEditingController,
                                onSaved: (v) => email = v ?? "",
                                validator: (v) => emailError,
                                onChanged: (v) {
                                  setState(() => emailError = null);
                                  validateForm();
                                },
                                decoration: CustomInputDecoration(
                                  context,
                                  labelText: "Email",
                                  hintText: 'Podaj swój adres e-mail',
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                obscureText: true,
                                obscuringCharacter: '*',
                                validator: (v) => passwordError,
                                onSaved: (v) => password = v ?? "",
                                onChanged: (v) {
                                  setState(() => passwordError = null);
                                  validateForm();
                                },
                                decoration: CustomInputDecoration(
                                  context,
                                  labelText: "Hasło",
                                  hintText: 'Wymyśl silne hasło',
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                obscureText: true,
                                obscuringCharacter: '*',
                                validator: (v) => password2Error,
                                onSaved: (v) => password2 = v ?? "",
                                onChanged: (v) {
                                  setState(() => password2Error = null);
                                  validateForm();
                                },
                                decoration: CustomInputDecoration(
                                  context,
                                  labelText: "Powtórz hasło",
                                  hintText: 'Wpisz swoje hasło',
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Theme.of(context).primaryColor,
                                  ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Masz już konto?',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.goToLogin,
                            child: const Text(
                              'Zaloguj się',
                              style: TextStyle(fontWeight: FontWeight.w500),
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
