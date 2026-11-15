import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const LatLng _defaultLocation = LatLng(
    8.503,
    125.971,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoFind Map'),
      ),
      body: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _defaultLocation,
          zoom: 14,
        ),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}