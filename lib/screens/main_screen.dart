import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:location/location.dart' as loc;
import 'package:our_cabss/assistants/assistant_method.dart';
import 'package:our_cabss/assistants/geofire_assistant.dart';
import 'package:our_cabss/infoHandler/app_info.dart';
import 'package:our_cabss/models/active_nearby_availble_drivers.dart';
import 'package:our_cabss/models/direction_details_info.dart';
import 'package:our_cabss/screens/drawer_screen.dart';
import 'package:our_cabss/screens/pecise_pickup_location.dart';
import 'package:our_cabss/services/auth_serviece.dart';
import 'package:our_cabss/widgets/progress_dilog.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  String? userName = "";
  String? userEmail = "";
  LatLng? pickUpLocation;

  loc.Location location = loc.Location();

  String? address = "";

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(25.5941, 85.1376),
    zoom: 14.0,
  );
  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  Position? userCurrentPosition;
  LocationPermission? _locationPermission;
  Set<Marker> markersSet = {};
  bool darkTheme = false;
  List<LatLng> polyLineCoordinatesList = [];
  Set<Polyline> polyLineSet = {};
  BitmapDescriptor? activeNearbyIcon;
  bool activeNearbyDriverKeysLoaded = false;

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateMapWithLocations();
    });
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

      await AssistentMethod.searchAddressForGeographicCoordinated(
        userCurrentPosition!,
        context,
      );

      if (userModelCurrentInfo != null) {
        userName = userModelCurrentInfo!.name ?? "";
        userEmail = userModelCurrentInfo!.email ?? "";

        initiallizeGeoFireListener();
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  initiallizeGeoFireListener() {
    Geofire.initialize("activeDrivers");
    Geofire.queryAtLocation(
      userCurrentPosition!.latitude,
      userCurrentPosition!.longitude,
      10,
    )!.listen((map) {
      print(map);
      if (map != null) {
        var callBack = map["callBack"];
        switch (callBack) {
          case Geofire.onKeyEntered:
            ActiveNearByAvailbleDrivers activeNearByAvailbleDrivers =
                ActiveNearByAvailbleDrivers();
            activeNearByAvailbleDrivers.locationLatitde = map["latitude"];
            activeNearByAvailbleDrivers.locationLongitude = map["longitude"];
            activeNearByAvailbleDrivers.driverId = map["key"];
            GeofireAssistant.activeNearByAvailbleDriversList.add(
              activeNearByAvailbleDrivers,
            );
            if (activeNearbyDriverKeysLoaded == true) {
              displayActiveDriversOnUserMap();
            }
            break;
          case Geofire.onKeyExited:
            GeofireAssistant.deleteOfflineDriverFromList(map["key"]);
            displayActiveDriversOnUserMap();
            break;
          case Geofire.onKeyMoved:
            ActiveNearByAvailbleDrivers activeNearByAvailbleDrivers =
                ActiveNearByAvailbleDrivers();
            activeNearByAvailbleDrivers.locationLatitde = map["latitude"];
            activeNearByAvailbleDrivers.locationLongitude = map["longitude"];
            activeNearByAvailbleDrivers.driverId = map["key"];
            GeofireAssistant.updateNearByAvailbleDriverLocation(
              activeNearByAvailbleDrivers,
            );
            displayActiveDriversOnUserMap();
            break;
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            displayActiveDriversOnUserMap();
            break;
        }
      }
      setState(() {});
    });
  }

  displayActiveDriversOnUserMap() {
    setState(() {
      markersSet.clear();

      Set<Marker> driversMarkerSet = Set<Marker>();
      for (ActiveNearByAvailbleDrivers eachDriver
          in GeofireAssistant.activeNearByAvailbleDriversList) {
        LatLng eachDriverActivePosition = LatLng(
          eachDriver.locationLatitde!,
          eachDriver.locationLongitude!,
        );
        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );
        driversMarkerSet.add(marker);
      }
      setState(() {
        markersSet = driversMarkerSet;
      });
    });
  }

  createActiveNearByDriverIconMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(
        context,
        size: Size(2, 2),
      );
      BitmapDescriptor.fromAssetImage(
        imageConfiguration,
        "assets/images/car.jpg",
      ).then((value) {
        activeNearbyIcon = value;
      });
    }
  }

  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async {
    var appInfo = Provider.of<AppInfo>(context, listen: false);
    var originPosition = appInfo.userPickUpLocation;
    var destinationPosition = appInfo.userDropOffLocation;

    if (originPosition == null || destinationPosition == null) {
      print("Origin or destination position is null");
      return;
    }

    var originLatLng = LatLng(
      originPosition.locationLatitude!,
      originPosition.locationLongitude!,
    );
    var destinationLatLng = LatLng(
      destinationPosition.locationLatitude!,
      destinationPosition.locationLongitude!,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          ProgressDilog(message: "Please wait..."),
    );

    try {
      var directionDetailsInfo =
          await AssistentMethod.obtainOriginToDestinationDirectionDetails(
            originLatLng,
            destinationLatLng,
          );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (directionDetailsInfo == null) {
        print("Failed to get direction details");
        return;
      }

      setState(() {
        tripDirectionDetailsInfo = directionDetailsInfo;
      });

      PolylinePoints pPoints = PolylinePoints(
        apiKey: 'AIzaSyCeUvUpxCAYciJZ4blCtMm7snAM8ODvmg4',
      );
      List<PointLatLng> decodedPolyLinePointsResultList =
          PolylinePoints.decodePolyline(directionDetailsInfo.encodedPoints!);

      polyLineCoordinatesList.clear();

      if (decodedPolyLinePointsResultList.isNotEmpty) {
        for (var pointLatLng in decodedPolyLinePointsResultList) {
          polyLineCoordinatesList.add(
            LatLng(pointLatLng.latitude, pointLatLng.longitude),
          );
        }
      }

      markersSet.clear();
      polyLineSet.clear();

      Marker originMarker = Marker(
        markerId: const MarkerId("originID"),
        position: originLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: originPosition.locationName!,
          snippet: "Origin",
        ),
      );

      Marker destinationMarker = Marker(
        markerId: const MarkerId("destinationID"),
        position: destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: destinationPosition.locationName!,
          snippet: "Destination",
        ),
      );

      Polyline polyline = Polyline(
        color: darkTheme ? Colors.amber : Colors.blue,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: polyLineCoordinatesList,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      setState(() {
        markersSet.add(originMarker);
        markersSet.add(destinationMarker);
        polyLineSet.add(polyline);
      });

      _fitMarkersInCamera(originLatLng, destinationLatLng);
    } catch (e) {
      print("Error drawing polyline: $e");
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _fitMarkersInCamera(LatLng originLatLng, LatLng destinationLatLng) {
    LatLngBounds bounds;

    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
        southwest: destinationLatLng,
        northeast: originLatLng,
      );
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      bounds = LatLngBounds(
        southwest: originLatLng,
        northeast: destinationLatLng,
      );
    }

    if (newGoogleMapController != null) {
      newGoogleMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 70),
      );
    }
  }

  void updateMapWithLocations() {
    var appInfo = Provider.of<AppInfo>(context, listen: false);

    if (newGoogleMapController == null) return;

    if (polyLineSet.isEmpty) {
      markersSet.clear();

      if (appInfo.userPickUpLocation != null) {
        var pickupLocation = appInfo.userPickUpLocation!;
        markersSet.add(
          Marker(
            markerId: const MarkerId("pickupID"),
            position: LatLng(
              pickupLocation.locationLatitude!,
              pickupLocation.locationLongitude!,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: "Pickup Location",
              snippet: pickupLocation.locationName,
            ),
          ),
        );
      }

      if (appInfo.userDropOffLocation != null) {
        var dropOffLocation = appInfo.userDropOffLocation!;
        markersSet.add(
          Marker(
            markerId: const MarkerId("dropOffID"),
            position: LatLng(
              dropOffLocation.locationLatitude!,
              dropOffLocation.locationLongitude!,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: "Drop Off Location",
              snippet: dropOffLocation.locationName,
            ),
          ),
        );

        if (appInfo.userPickUpLocation != null) {
          _fitBothLocations(appInfo.userPickUpLocation!, dropOffLocation);
        } else {
          _focusOnLocation(dropOffLocation);
        }
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _fitBothLocations(var pickup, var dropOff) {
    double minLat = pickup.locationLatitude < dropOff.locationLatitude
        ? pickup.locationLatitude
        : dropOff.locationLatitude;
    double maxLat = pickup.locationLatitude > dropOff.locationLatitude
        ? pickup.locationLatitude
        : dropOff.locationLatitude;
    double minLng = pickup.locationLongitude < dropOff.locationLongitude
        ? pickup.locationLongitude
        : dropOff.locationLongitude;
    double maxLng = pickup.locationLongitude > dropOff.locationLongitude
        ? pickup.locationLongitude
        : dropOff.locationLongitude;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    if (newGoogleMapController != null) {
      newGoogleMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  void _focusOnLocation(var location) {
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(location.locationLatitude!, location.locationLongitude!),
      zoom: 14,
    );

    if (newGoogleMapController != null) {
      newGoogleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: _scaffoldState,
        drawer: DrawerScreen(),
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
              polylines: polyLineSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;
                locateUserPosition();
              },
            ),

            Positioned(
              top: 50,
              left: 20,
              child: Container(
                child: GestureDetector(
                  child: CircleAvatar(
                    backgroundColor: darkTheme
                        ? Colors.amber.shade400
                        : Colors.white,
                    child: Icon(
                      Icons.menu,
                      color: darkTheme ? Colors.black : Colors.lightBlue,
                    ),
                  ),
                  onTap: () {
                    _scaffoldState.currentState!.openDrawer();
                  },
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
                  boxShadow: [
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
                    _buildLocationRow(
                      icon: Icons.my_location,
                      label: "From",
                      address:
                          Provider.of<AppInfo>(
                            context,
                          ).userPickUpLocation?.locationName ??
                          "Getting current location...",
                      onTap: () async {
                        var result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => PecisePickupLocationScreen(),
                          ),
                        );
                        if (result != null) {
                          updateMapWithLocations();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      thickness: 1,
                    ),
                    const SizedBox(height: 8),
                    _buildLocationRow(
                      icon: Icons.location_on,
                      label: "To",
                      address:
                          Provider.of<AppInfo>(
                            context,
                          ).userDropOffLocation?.locationName ??
                          "Where to?",
                      onTap: () async {
                        var result = await Navigator.pushNamed(
                          context,
                          "/SearchPlacesScreen",
                        );
                        if (result == "obtainedDropOff") {
                          updateMapWithLocations();
                          await drawPolyLineFromOriginToDestination(darkTheme);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              var result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => PecisePickupLocationScreen(),
                                ),
                              );
                              if (result != null) {
                                updateMapWithLocations();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkTheme
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Change Pickup",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkTheme
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              var appInfo = Provider.of<AppInfo>(
                                context,
                                listen: false,
                              );
                              if (appInfo.userPickUpLocation != null &&
                                  appInfo.userDropOffLocation != null) {
                                Navigator.pushNamed(
                                  context,
                                  "/RequestRideScreen",
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Please select both pickup and destination locations",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkTheme
                                  ? Colors.amber
                                  : Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Request Ride",
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String address,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address.length > 40
                    ? "${address.substring(0, 40)}..."
                    : address,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
