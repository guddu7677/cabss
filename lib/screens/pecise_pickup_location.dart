import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:our_cabss/assistents/assistent_method.dart';
import 'package:our_cabss/infoHandler/app_info.dart';
import 'package:our_cabss/services/auth_serviece.dart';
import 'package:provider/provider.dart';

class PecisePickupLocationScreen extends StatefulWidget {
  const PecisePickupLocationScreen({super.key});

  @override
  State<PecisePickupLocationScreen> createState() =>
      _PecisePickupLocationScreenState();
}

class _PecisePickupLocationScreenState
    extends State<PecisePickupLocationScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  LatLng? pickUpLocation;
  loc.Location location = loc.Location();
  String? address = "";
  bool darkTheme = false;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(25.5941, 85.1376),
    zoom: 14.0,
  );

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  Position? userCurrentPosition;
  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;
  Set<Marker> markersSet = {};
  Set<Polyline> polyLineSet = {};

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  Future<void> checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.checkPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }

    if (_locationPermission == LocationPermission.whileInUse ||
        _locationPermission == LocationPermission.always) {
      locateUserPosition();
    }
  }

  Future<void> locateUserPosition() async {
    try {
      Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      userCurrentPosition = cPosition;

      LatLng latLngPosition = LatLng(
        userCurrentPosition!.latitude,
        userCurrentPosition!.longitude,
      );

      CameraPosition cameraPosition = CameraPosition(
        target: latLngPosition,
        zoom: 14,
      );

      if (newGoogleMapController != null) {
        newGoogleMapController!.animateCamera(
          CameraUpdate.newCameraPosition(cameraPosition),
        );
      }

      String humanReadableAddress =
          await AssistentMethod.searchAddressForGeographicCoordinated(
        userCurrentPosition!,
        context,
      );

      setState(() {
        address = humanReadableAddress;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void getAddressFromLatLng(LatLng position) async {
    try {
      Position userPosition = Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      String humanReadableAddress =
          await AssistentMethod.searchAddressForGeographicCoordinated(
        userPosition,
        context,
      );

      setState(() {
        address = humanReadableAddress;
        pickUpLocation = position;
      });
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            markers: markersSet,
            onCameraMove: (CameraPosition position) {
              pickUpLocation = position.target;
            },
            onCameraIdle: () {
              if (pickUpLocation != null) {
                getAddressFromLatLng(pickUpLocation!);
              }
            },
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              locateUserPosition();
            },
          ),

          Center(
            child: Container(
              child: Icon(
                Icons.location_on,
                size: 40,
                color: darkTheme ? Colors.amber : Colors.blue,
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkTheme ? Colors.black87 : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Set Pickup Location",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkTheme ? Colors.amber : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: darkTheme ? Colors.amber : Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            address ?? "Getting address...",
                            style: TextStyle(
                              fontSize: 14,
                              color: darkTheme ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (pickUpLocation != null && address != null && address!.isNotEmpty) {
                          var appInfo = Provider.of<AppInfo>(context, listen: false);
                        
                          Navigator.pop(context, "pickupLocationSet");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkTheme ? Colors.amber : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Confirm Pickup Location",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkTheme ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}