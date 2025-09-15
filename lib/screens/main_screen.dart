import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as log;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:our_cabss/assistents/assistent_method.dart';
import 'package:geocoding/geocoding.dart';
import 'package:our_cabss/infoHandler/app_info.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainPageState();
}

class _MainPageState extends State<MainScreen> {
  LatLng? pickedLocation;
  log.Location location = log.Location();
  String? address;
  bool darkTheme = false;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight = 220.0;
  double waitingResponseContainerHeight = 0.0;
  double assignedDriverInfoContainerHeight = 0.0;

  Position? userCurrentPosition;
  var geoLocator = Geolocator();
  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  bool openNavigationDrawer = true;
  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  locateUserposition() async {
    Position cposition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    userCurrentPosition = cposition;

    LatLng latLatPosition = LatLng(
      userCurrentPosition!.latitude,
      userCurrentPosition!.longitude,
    );

    CameraPosition cameraPosition = CameraPosition(
      target: latLatPosition,
      zoom: 14,
    );
    newGoogleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );

    String humanReadableAddress =
        await AssistentMethod.searchAddressForGeographicCoordinated(
          userCurrentPosition!,
          context,
        );
  }

  // Method to update map when drop-off location is selected
  void updateMapWithDropOffLocation() async {
    if (Provider.of<AppInfo>(context, listen: false).userDropOffLocation != null) {
      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation!;
      
      // Clear existing markers
      markersSet.clear();
      
      // Add pickup location marker
      if (Provider.of<AppInfo>(context, listen: false).userPickUpLocation != null) {
        var pickupLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation!;
        markersSet.add(
          Marker(
            markerId: const MarkerId("pickupID"),
            position: LatLng(pickupLocation.locationLatitude!, pickupLocation.locationLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: "Pickup Location", snippet: pickupLocation.locationName),
          ),
        );
      }
      
      // Add drop-off location marker
      markersSet.add(
        Marker(
          markerId: const MarkerId("dropOffID"),
          position: LatLng(dropOffLocation.locationLatitude!, dropOffLocation.locationLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: "Drop Off Location", snippet: dropOffLocation.locationName),
        ),
      );

      if (Provider.of<AppInfo>(context, listen: false).userPickUpLocation != null) {
        var pickupLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation!;
        
        double minLat = pickupLocation.locationLatitude! < dropOffLocation.locationLatitude! 
            ? pickupLocation.locationLatitude! : dropOffLocation.locationLatitude!;
        double maxLat = pickupLocation.locationLatitude! > dropOffLocation.locationLatitude! 
            ? pickupLocation.locationLatitude! : dropOffLocation.locationLatitude!;
        double minLng = pickupLocation.locationLongitude! < dropOffLocation.locationLongitude! 
            ? pickupLocation.locationLongitude! : dropOffLocation.locationLongitude!;
        double maxLng = pickupLocation.locationLongitude! > dropOffLocation.locationLongitude! 
            ? pickupLocation.locationLongitude! : dropOffLocation.locationLongitude!;

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        newGoogleMapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100.0),
        );
      } else {
        CameraPosition cameraPosition = CameraPosition(
          target: LatLng(dropOffLocation.locationLatitude!, dropOffLocation.locationLongitude!),
          zoom: 14,
        );
        newGoogleMapController!.animateCamera(
          CameraUpdate.newCameraPosition(cameraPosition),
        );
      }

      setState(() {});
    }
  }

  getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pickedLocation!.latitude,
        pickedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          address =
              "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      print("Error getting address: $e");
      setState(() {
        address = "Address not found";
      });
    }
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  @override
  Widget build(BuildContext context) {
    darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
              mapType: MapType.normal,
              myLocationButtonEnabled: true,
              initialCameraPosition: _kGooglePlex,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              polylines: polylineSet,
              markers: markersSet,
              circles: circlesSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;
                setState(() {});
                locateUserposition();
              },
              onCameraMove: (CameraPosition position) {
                if (pickedLocation != position.target) {
                  setState(() {
                    pickedLocation = position.target;
                  });
                }
              },
              onCameraIdle: () {
                getAddressFromLatLng();
              },
            ),
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.location_on, color: Colors.red, size: 30),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.black54 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: darkTheme
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: darkTheme
                                        ? Colors.amber.shade400
                                        : Colors.blue,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "From",
                                    style: TextStyle(
                                      color: darkTheme
                                          ? Colors.amber.shade400
                                          : Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      Provider.of<AppInfo>(
                                                    context,
                                                  ).userPickUpLocation !=
                                                  null
                                          ? (Provider.of<AppInfo>(context)
                                                        .userPickUpLocation!
                                                        .locationName!)
                                                    .substring(0, 
                                                      Provider.of<AppInfo>(context)
                                                        .userPickUpLocation!
                                                        .locationName!.length > 30 
                                                          ? 30 
                                                          : Provider.of<AppInfo>(context)
                                                              .userPickUpLocation!
                                                              .locationName!.length) +
                                                (Provider.of<AppInfo>(context)
                                                        .userPickUpLocation!
                                                        .locationName!.length > 30 
                                                    ? "..." 
                                                    : "")
                                          : "address not found",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Divider(
                              height: 1,
                              thickness: 2,
                              color: darkTheme
                                  ? Colors.amber.shade400
                                  : Colors.blue,
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.all(5.0),
                              child: GestureDetector(
                                onTap: () async {
                                  var responseFromSearchScreen = await Navigator.pushNamed(context, "/SearchPlacesScreen");
                                  if (responseFromSearchScreen == "obtainedDropOff") {
                                    setState(() {
                                      openNavigationDrawer = false;
                                    });
                                    // Update the map with the new drop-off location
                                    updateMapWithDropOffLocation();
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: darkTheme
                                          ? Colors.amber.shade400
                                          : Colors.blue,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "To",
                                      style: TextStyle(
                                        color: darkTheme
                                            ? Colors.amber.shade400
                                            : Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        Provider.of<AppInfo>(
                                                      context,
                                                    ).userDropOffLocation !=
                                                    null
                                            ? (Provider.of<AppInfo>(context)
                                                          .userDropOffLocation!
                                                          .locationName!)
                                            : " where to?",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}