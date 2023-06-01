import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng _selectedLocation = LatLng(0, 0);

  void _handleTap(TapPosition _, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      print('Selected location: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(50, 20),
        zoom: 13.0,
        onTap: _handleTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _selectedLocation,
              width: 35,
              height: 35,
              builder: (context) => const Image(image: AssetImage("assets/pinBlue.png")),
            ),
          ],
        ),
      ],
    );
  }
}
