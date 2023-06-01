import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationModel extends ChangeNotifier {
  LocationPermission _permissionState = LocationPermission.denied;
  bool _serviceEnabled = false;

  LocationPermission get permissionState => _permissionState;
  bool get serviceEnabled => _serviceEnabled;
  Future<Position?> get location => getLocation();

  Future<Position?> getLocation() async {
    if (!_serviceEnabled) return null;

    if ([LocationPermission.denied, LocationPermission.deniedForever].contains(_permissionState)) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<bool> askForPermission() async {
    _permissionState = await Geolocator.checkPermission();
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();

    if (!_serviceEnabled) {
      return false;
    }

    if (_permissionState == LocationPermission.denied) {
      _permissionState = await Geolocator.requestPermission();
      notifyListeners();

      if (_permissionState == LocationPermission.denied) {
        return false;
      }
    }

    if (_permissionState == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}
