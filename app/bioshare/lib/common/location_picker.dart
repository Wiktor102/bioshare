import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

// model classes
import '../models/location_model.dart';

class LocationPicker extends StatefulWidget {
  final Function(LatLng) onSelected;
  final LatLng? mapCenter;
  const LocationPicker({
    required this.onSelected,
    this.mapCenter,
    super.key,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _selectedLocation;
  Future<Position?>? locationFuture;

  void _handleTap(TapPosition _, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });

    widget.onSelected(latLng);
  }

  @override
  Widget build(BuildContext context) {
    if (locationFuture == null) {
      final locationProvider = Provider.of<LocationModel>(context);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          locationFuture = locationProvider.location;
        });
      });

      return const Align(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return FutureBuilder<Position?>(
      future: locationFuture,
      builder: (context, AsyncSnapshot<Position?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Align(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(),
            ),
          );
        }

        LatLng? center = widget.mapCenter;
        var pos = snapshot.data;

        if (center == null && pos != null) {
          center = LatLng(pos.latitude, pos.longitude);
        }

        center ??= LatLng(50, 20);

        return FlutterMap(
          options: MapOptions(
            center: center,
            zoom: 13.0,
            onTap: _handleTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.shopper',
            ),
            CurrentLocationLayer(),
            _selectedLocation != null
                ? MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 35,
                        height: 35,
                        builder: (context) => const Image(image: AssetImage("assets/pinBlue.png")),
                      ),
                    ],
                  )
                : Container(),
          ],
        );
      },
    );
  }
}
