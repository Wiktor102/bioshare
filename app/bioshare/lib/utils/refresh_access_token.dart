import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import './session_expired.dart';

Future<void> refreshAccessToken() async {
  String? refreshToken = await App.secureStorage.read(key: "refreshToken");

  if (refreshToken == null) {
    sessionExpired(null);
    return;
  }

  Uri uri = Uri.parse("http://bioshareapi.wiktorgolicz.pl/auth/getNewAccessToken.php");
  if (!kReleaseMode) {
    uri = Uri.parse("http://192.168.1.66:4000/auth/getNewAccessToken.php");
  }

  try {
    final http.Response response = await http.get(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $refreshToken',
      },
    );

    if (response.statusCode == 403) {
      sessionExpired(null);
      return;
    }

    if (response.body == "") {
      throw Exception(response.statusCode);
    }

    dynamic decodedResponse;

    try {
      decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    } catch (e) {
      throw Exception(response.body);
    }

    if (response.statusCode != 200) {
      throw Exception("#${response.statusCode}: $decodedResponse");
    }

    await App.secureStorage.write(key: "jwt", value: decodedResponse["token"]);
  } catch (e, s) {
    print(e);
    print(s);
    sessionExpired(null);
  }
}
