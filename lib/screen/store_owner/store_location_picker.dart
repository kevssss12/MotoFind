import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StoreLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const StoreLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<StoreLocationPicker> createState() =>
      _StoreLocationPickerState();
}

class _StoreLocationPickerState
    extends State<StoreLocationPicker> {
 

  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();

    // Existing store location
    if (widget.initialLatitude != null &&
        widget.initialLongitude != null) {
      selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    } else {
      // Default location
      // San Francisco, Agusan del Sur
      selectedLocation = const LatLng(
        8.5004,
        125.9760,
      );
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      selectedLocation = location;
    });
  }

  void _saveLocation() {
    Navigator.pop(
      context,
      {
        "latitude": selectedLocation.latitude,
        "longitude": selectedLocation.longitude,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Store Location",
        ),
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation,
              zoom: 17,
            ),

            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,

            onTap: _onMapTap,

            markers: {
              Marker(
                markerId:
                    const MarkerId("store_location"),

                position: selectedLocation,

                draggable: true,

                onDragEnd: (newPosition) {
                  setState(() {
                    selectedLocation = newPosition;
                  });
                },

                infoWindow: const InfoWindow(
                  title: "Store Location",
                  snippet:
                      "Drag or tap the map to move",
                ),
              ),
            },
          ),

          // ==================================================
          // INSTRUCTION
          // ==================================================

          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Card(
              elevation: 4,
              child: Padding(
                padding:
                    const EdgeInsets.all(12),
                child: Row(
                  children: const [
                    Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Tap the exact location of your store "
                        "on the map or drag the marker.",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==================================================
          // COORDINATES
          // ==================================================

          Positioned(
            left: 15,
            right: 15,
            bottom: 90,
            child: Card(
              elevation: 4,
              child: Padding(
                padding:
                    const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selected Location",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Latitude: "
                      "${selectedLocation.latitude.toStringAsFixed(8)}",
                    ),

                    Text(
                      "Longitude: "
                      "${selectedLocation.longitude.toStringAsFixed(8)}",
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==================================================
          // SAVE BUTTON
          // ==================================================

          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _saveLocation,
                icon: const Icon(
                  Icons.check,
                ),
                label: const Text(
                  "SAVE LOCATION",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}