import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// utilities
import 'utils/pdf_api.dart';
import "utils/show_popup.dart";

// common widgets
import "common/custom_input_decoration.dart";
import 'common/pdv_viewer.dart';

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
  String username = "";
  String password = "";
  String password2 = "";

  String? emailError;
  String? usernameError;
  String? passwordError;
  String? password2Error;

  bool loading = false;

  @override
  void dispose() {
    _textEditingController.clear();
    super.dispose();
  }

  void onFormSubmitted(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      loading = true;
    });

    _formKey.currentState!.save();
    Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/auth/signUp.php");
    if (!kReleaseMode) {
      uri = Uri.parse("http://192.168.1.66:4000/auth/signUp.php");
    }

    if (email.isEmpty) {
      emailError = "Podaj adres e-mail";
    }

    if (username.isEmpty) {
      usernameError = "Wymyśl nazwę użytkownika";
    }

    if (username.contains("@")) {
      usernameError = "Nazwa nie może zawierać @";
    }

    if (username.length > 70) {
      usernameError = "Za długa nazwa (max. 70 znaków)";
    }

    if (password.isEmpty) {
      passwordError = "Wymyśl hasło";
    }

    if (emailError != null || usernameError != null || passwordError != null) {
      validateForm();
      return;
    }

    final String body = json.encode({
      "mail": email,
      "username": username,
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

      if (response.statusCode == 400 || response.statusCode == 409) {
        setState(() {
          for (var error in decodedResponse["errors"]) {
            switch (error["type"]) {
              case "mail":
                if (emailError != null) break;
                emailError = error["error"];
                break;
              case "username":
                if (usernameError != null) break;
                usernameError = error["error"];
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
        return;
      }

      if (response.statusCode != 200) {
        throw Exception(decodedResponse.error);
      }

      print(decodedResponse["userId"]);

      widget.goToLogin();
      if (!context.mounted) return;
      showPopup(context, "Rejestracja pomyślna", "Teraz możesz sie zalogować.");
    } catch (e) {
      showPopup(context, "Wystąpił nieznany błąd", "Przepraszamy. Proszę spróbować później.");
    } finally {
      validateForm();

      setState(() {
        loading = false;
      });
    }
  }

  validateForm() => _formKey.currentState!.validate();

  showPdf(String path, String filename, String title) async {
    final file = await PdfApi.loadAsset(path, filename);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MyPdfViewer(pdfPath: file.path, title: title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

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
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  autofillHints: const [AutofillHints.newUsername],
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
                                    prefixIcon: Icons.email,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextFormField(
                                  onSaved: (v) => username = v ?? "",
                                  validator: (v) => usernameError,
                                  onChanged: (v) {
                                    setState(() => usernameError = null);
                                    validateForm();
                                  },
                                  decoration: CustomInputDecoration(
                                    context,
                                    labelText: "Nazwa użytkownika",
                                    hintText: 'Nazwa będzie publiczna',
                                    prefixIcon: Icons.person,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextFormField(
                                  autofillHints: const [AutofillHints.newPassword],
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
                                    prefixIcon: Icons.lock,
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
                                    hintText: 'Powtórz hasło',
                                    prefixIcon: Icons.lock,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.85),
                                        fontSize: 13,
                                      ),
                                      children: <TextSpan>[
                                        const TextSpan(text: 'Klikając Kontynuuj zgadzasz się z '),
                                        TextSpan(
                                            text: 'Regulaminem',
                                            style: linkStyle,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () =>
                                                  showPdf("assets/regulamin.pdf", "regulamin.pdf", "Regulamin")),
                                        const TextSpan(text: ' i z '),
                                        TextSpan(
                                            text: 'Polityką prywatności',
                                            style: linkStyle,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => showPdf(
                                                  "assets/polityka.pdf", "polityka.pdf", "Polityka Prywatności")),
                                      ],
                                    ),
                                  ),
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
                            'Masz już konto?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.85),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.goToLogin,
                            child: Text(
                              'Zaloguj się',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
