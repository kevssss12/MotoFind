
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreLocationScreen extends StatefulWidget {
  final double storeLatitude;
  final double storeLongitude;
  final String storeName;

  const StoreLocationScreen({
    super.key,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.storeName,
  });

  @override
  State<StoreLocationScreen> createState() =>
      _StoreLocationScreenState();
}

class _StoreLocationScreenState
    extends State<StoreLocationScreen> {
  GoogleMapController? mapController;

  Position? customerPosition;

  StreamSubscription<Position>? positionStreamSubscription;

  bool isLoadingLocation = true;
  bool followCustomer = true;

  String? locationError;

  late LatLng storeLocation;

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();

    storeLocation = LatLng(
      widget.storeLatitude,
      widget.storeLongitude,
    );

    // Web and Windows EXE use external Google Maps.
    // Android keeps the original GPS and Google Maps behavior.
    if (!kIsWeb && !Platform.isWindows) {
      loadCustomerLocation();
    } else {
      isLoadingLocation = false;
    }
  }

  // ============================================================
  // WINDOWS / WEB: OPEN STORE LOCATION IN GOOGLE MAPS
  // ============================================================

  Future<void> openStoreInGoogleMaps() async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${widget.storeLatitude},${widget.storeLongitude}',
    );

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open Google Maps. '
              'Please check your browser and internet connection.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('OPEN GOOGLE MAPS ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Maps.'),
        ),
      );
    }
  }

  // ============================================================
  // WINDOWS / WEB: OPEN DIRECTIONS IN GOOGLE MAPS
  // ============================================================

  Future<void> openDirectionsInGoogleMaps() async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.storeLatitude},${widget.storeLongitude}'
      '&travelmode=driving',
    );

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open directions. '
              'Please check your browser and internet connection.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('OPEN GOOGLE MAPS DIRECTIONS ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open directions.'),
        ),
      );
    }
  }

  // ============================================================
  // WINDOWS / WEB: MAP VIEW
  // ============================================================

  Widget buildWindowsMapView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Location'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 650,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.map,
                      size: 76,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'MotoFind Store Location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.storeName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'View the motorcycle parts store on Google Maps '
                      'or get driving directions using your browser.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Store Coordinates',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            'Latitude: ${widget.storeLatitude}\n'
                            'Longitude: ${widget.storeLongitude}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: openStoreInGoogleMaps,
                        icon: const Icon(Icons.location_on),
                        label: const Text(
                          'View Store on Google Maps',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: openDirectionsInGoogleMaps,
                        icon: const Icon(Icons.directions),
                        label: const Text(
                          'Get Directions',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Note: Google Maps opens in your default browser. '
                      'Allow location access in the browser if you want '
                      'Google Maps to use your current location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GET CUSTOMER LOCATION + START REAL-TIME GPS
  // ============================================================

  Future<void> loadCustomerLocation() async {
    try {
      if (mounted) {
        setState(() {
          isLoadingLocation = true;
          locationError = null;
        });
      }

      // ========================================================
      // CHECK GPS / LOCATION SERVICE
      // ========================================================

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
          locationError =
              "Location/GPS is turned off.\n\n"
              "Please turn on Location on your device.";
        });

        return;
      }

      // ========================================================
      // CHECK LOCATION PERMISSION
      // ========================================================

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
          locationError =
              "Location permission was denied.";
        });

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
          locationError =
              "Location permission is permanently denied.\n\n"
              "Please enable location permission in Android Settings.";
        });

        return;
      }

      // ========================================================
      // GET INITIAL CURRENT LOCATION
      // ========================================================

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      if (!mounted) return;

      customerPosition = position;

      debugPrint("================================");
      debugPrint("CUSTOMER INITIAL GPS LOCATION");
      debugPrint("LATITUDE: ${position.latitude}");
      debugPrint("LONGITUDE: ${position.longitude}");
      debugPrint("================================");

      // ========================================================
      // CREATE INITIAL MARKERS
      // ========================================================

      updateMarkers(position);

      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }

      // ========================================================
      // SHOW BOTH LOCATIONS
      // ========================================================

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      if (mapController != null) {
        await showBothLocations();
      }

      // ========================================================
      // START REAL-TIME LOCATION STREAM
      // ========================================================

      startLocationStream();
    } catch (e) {
      debugPrint("DEVICE LOCATION ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
        locationError =
            "Unable to get your device location.\n\n$e";
      });
    }
  }

  // ============================================================
  // START REAL-TIME LOCATION STREAM
  // ============================================================

  void startLocationStream() {
    // Prevent duplicate streams.
    positionStreamSubscription?.cancel();

    const LocationSettings locationSettings =
        LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    positionStreamSubscription =
        Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!mounted) return;

        customerPosition = position;

        debugPrint(
          "REAL-TIME CUSTOMER LOCATION: "
          "${position.latitude}, ${position.longitude}",
        );

        // ======================================================
        // UPDATE CUSTOMER MARKER
        // ======================================================

        updateMarkers(position);

        // ======================================================
        // FOLLOW CUSTOMER
        // ======================================================

        if (followCustomer && mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(
                position.latitude,
                position.longitude,
              ),
            ),
          );
        }
      },
      onError: (error) {
        debugPrint(
          "REAL-TIME LOCATION STREAM ERROR: $error",
        );
      },
    );
  }

  // ============================================================
  // UPDATE MARKERS
  // ============================================================

  void updateMarkers(Position position) {
    final Set<Marker> newMarkers = {
      // ========================================================
      // CUSTOMER MARKER
      // ========================================================

      Marker(
        markerId: const MarkerId(
          "customer_location",
        ),
        position: LatLng(
          position.latitude,
          position.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(
          title: "Your Location",
        ),
      ),

      // ========================================================
      // STORE MARKER
      // ========================================================

      Marker(
        markerId: const MarkerId(
          "store_location",
        ),
        position: storeLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: widget.storeName,
          snippet: "Store Location",
        ),
      ),
    };

    if (!mounted) return;

    setState(() {
      markers = newMarkers;
    });
  }

  // ============================================================
  // SHOW CUSTOMER + STORE
  // ============================================================

  Future<void> showBothLocations() async {
    if (mapController == null ||
        customerPosition == null) {
      return;
    }

    final LatLng customerLocation = LatLng(
      customerPosition!.latitude,
      customerPosition!.longitude,
    );

    final LatLng store = storeLocation;

    final double minLat =
        customerLocation.latitude < store.latitude
            ? customerLocation.latitude
            : store.latitude;

    final double maxLat =
        customerLocation.latitude > store.latitude
            ? customerLocation.latitude
            : store.latitude;

    final double minLng =
        customerLocation.longitude < store.longitude
            ? customerLocation.longitude
            : store.longitude;

    final double maxLng =
        customerLocation.longitude > store.longitude
            ? customerLocation.longitude
            : store.longitude;

    // ==========================================================
    // CUSTOMER AND STORE ARE VERY CLOSE
    // ==========================================================

    if ((maxLat - minLat).abs() < 0.0005 &&
        (maxLng - minLng).abs() < 0.0005) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          customerLocation,
          17,
        ),
      );

      return;
    }

    // ==========================================================
    // FIT CUSTOMER + STORE
    // ==========================================================

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        minLat,
        minLng,
      ),
      northeast: LatLng(
        maxLat,
        maxLng,
      ),
    );

    try {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          120,
        ),
      );
    } catch (e) {
      debugPrint("MAP CAMERA ERROR: $e");
    }
  }

  // ============================================================
  // MAP CREATED
  // ============================================================

  void onMapCreated(
    GoogleMapController controller,
  ) {
    mapController = controller;

    debugPrint("GOOGLE MAP CONTROLLER READY");

    if (customerPosition != null) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          if (mounted) {
            showBothLocations();
          }
        },
      );
    }
  }

  // ============================================================
  // CENTER CUSTOMER + STORE
  // ============================================================

  Future<void> centerLocations() async {
    if (customerPosition == null) {
      await loadCustomerLocation();
      return;
    }

    await showBothLocations();
  }

  // ============================================================
  // STOP / RESUME FOLLOWING CUSTOMER
  // ============================================================

  void toggleFollowCustomer() {
    setState(() {
      followCustomer = !followCustomer;
    });

    if (followCustomer && customerPosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            customerPosition!.latitude,
            customerPosition!.longitude,
          ),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    positionStreamSubscription?.cancel();
    mapController?.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Web and Windows use external Google Maps.
    // Check kIsWeb first so Platform.isWindows is never
    // evaluated when the application runs in a browser.
    if (kIsWeb || Platform.isWindows) {
      return buildWindowsMapView();
    }

    // ==========================================================
    // ORIGINAL ANDROID GOOGLE MAP UI
    // ==========================================================

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Store Location",
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ====================================================
          // GOOGLE MAP
          // ====================================================

          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: storeLocation,
              zoom: 14,
            ),
            onMapCreated: onMapCreated,
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: true,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
            onCameraMoveStarted: () {
              // User manually moved the map.
              // Real-time markers continue updating,
              // but automatic camera following stops.
              if (followCustomer) {
                setState(() {
                  followCustomer = false;
                });
              }
            },
          ),

          // ====================================================
          // REAL-TIME FOLLOW BUTTON
          // ====================================================

          Positioned(
            right: 15,
            top: 15,
            child: Card(
              elevation: 5,
              child: IconButton(
                tooltip: followCustomer
                    ? "Stop following my location"
                    : "Follow my location",
                onPressed: toggleFollowCustomer,
                icon: Icon(
                  followCustomer
                      ? Icons.gps_fixed
                      : Icons.gps_not_fixed,
                ),
              ),
            ),
          ),

          // ====================================================
          // LOADING
          // ====================================================

          if (isLoadingLocation)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.85),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 15),
                          Text(
                            "Getting your location...",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Please wait.",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ====================================================
          // LOCATION ERROR
          // ====================================================

          if (locationError != null)
            Positioned(
              left: 15,
              right: 15,
              top: 15,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_off,
                        color: Colors.red,
                        size: 35,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        locationError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: loadCustomerLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Try Again"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ====================================================
          // STORE INFO
          // ====================================================

          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      child: Icon(
                        Icons.store,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.red,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Store Location",
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (customerPosition != null) ...[
                            const SizedBox(height: 3),
                            const Row(
                              children: [
                                Icon(
                                  Icons.person_pin_circle,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Blue = Your Location",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Row(
                              children: [
                                Icon(
                                  Icons.my_location,
                                  size: 15,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "GPS location updates automatically",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ==================================================
                    // CENTER BUTTON
                    // ==================================================

                    IconButton(
                      tooltip: "Show both locations",
                      onPressed: centerLocations,
                      icon: const Icon(
                        Icons.center_focus_strong,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
