import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
import 'package:our_cabss/splash_screen/splash_screen.dart';
import 'package:our_cabss/widgets/pay_fare_amount.dart';
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
  double searchLocationContainerHeight = 220;
  double waitingResponcefrommDriverHeight = 0;
  double assignDriverInfoContainerHeight = 0;
  double suggestedRideContainerHeight = 0;
  double serchingForDriverContainerHeight = 0;
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
  bool openNavigationDriver = false;
  double bottomPaddingOfMap = 0;
  Set<Marker> markSet = {};
  Set<Circle> circleSet = {};
  String selectedVehicleType = "";
  DatabaseReference? referenceRideRequest;
  String driverRideStatus = "Driver is coming";
  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubscription;
  String userRideRequestStatus = "";
  List<ActiveNearByAvailbleDrivers> onlineNearByAvailbleDriversList = [];
  bool requestPositionInfo = true;

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
            activeNearByAvailbleDrivers.locationLatitude = map["latitude"];
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
            activeNearByAvailbleDrivers.locationLatitude = map["latitude"];
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
          eachDriver.locationLatitude!,
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
        "assets/images/car.png",
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

  void showSearchingForDriversContainer() {
    setState(() {
      serchingForDriverContainerHeight = 200;
    });
  }

  void showSuggestedRideContainer() {
    setState(() {
      suggestedRideContainerHeight = 400;
      bottomPaddingOfMap = 400;
    });
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

  saveRideRequestInformation(selectedVehicleType) {
    referenceRideRequest = FirebaseDatabase.instance
        .ref()
        .child("All Rde Requests")
        .push();
    var originLocation = Provider.of<AppInfo>(
      context,
      listen: false,
    ).userPickUpLocation;
    var destinationLocation = Provider.of<AppInfo>(
      context,
      listen: false,
    ).userDropOffLocation;

    Map originLocationMap = {
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };
    Map destinationLocationMap = {
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };
    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId": "waiting",
    };
    referenceRideRequest!.set(userInformationMap);
    tripRideRequestInfoStreamSubscription = referenceRideRequest!.onValue
        .listen((eventSnap) async {
          if (eventSnap.snapshot.value == null) {
            return;
          }
          if ((eventSnap.snapshot.value as Map)["car_details"] != null) {
            setState(() {
              driverCarDetails =
                  (eventSnap.snapshot.value as Map)["car_details"].toString();
            });
          }
          if ((eventSnap.snapshot.value as Map)["driverPhone"] != null) {
            setState(() {
              driverCarDetails =
                  (eventSnap.snapshot.value as Map)["driverPhone"].toString();
            });
          }
          if ((eventSnap.snapshot.value as Map)["driverName"] != null) {
            setState(() {
              driverCarDetails = (eventSnap.snapshot.value as Map)["driverName"]
                  .toString();
            });
          }
          if ((eventSnap.snapshot.value as Map)["status"] != null) {
            setState(() {
              userRideRequestStatus =
                  (eventSnap.snapshot.value as Map)["status"].toString();
            });
          }
          if ((eventSnap.snapshot.value as Map)["driverLocation"] != null) {
            double driverCurrentPositionLat = double.parse(
              (eventSnap.snapshot.value as Map)["driverLocation"]["latitude"]
                  .toString(),
            );
            double driverCurrentPositionLng = double.parse(
              (eventSnap.snapshot.value as Map)["driverLocation"]["longitude"]
                  .toString(),
            );
            LatLng driverCurrentPositionLatLng = LatLng(
              driverCurrentPositionLat,
              driverCurrentPositionLng,
            );
            if (userRideRequestStatus == "accepted") {
              updateArrivalTimeToUserPickUpLocation(
                driverCurrentPositionLatLng,
              );
            }
            if (userRideRequestStatus == "arrived") {
              setState(() {
                driverRideStatus = "Driver has arrived";
              });
            }
            if (userRideRequestStatus == "ontrip") {
              updateReachingTimeToUserDropOffLocation(
                driverCurrentPositionLatLng,
              );
            }
            if (userRideRequestStatus == "ended") {
              if ((eventSnap.snapshot.value as Map)["fareAmount"] != null) {
                double fareAmount = double.parse(
                  (eventSnap.snapshot.value as Map)["fareAmount"].toString(),
                );
                var responce = await showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      PayFareAmountDilog(fareAmount: fareAmount),
                );
                if (responce == "Cash Paid") {
                  if ((eventSnap.snapshot.value as Map)["driverId"] != null) {
                    String assignedDriverId =
                        (eventSnap.snapshot.value as Map)["driverId"]
                            .toString();
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (c) => RateDriverScreen()),
                    // );

                    referenceRideRequest!.onDisconnect();
                    tripRideRequestInfoStreamSubscription!.cancel();
                  }
                }
              }
            }
          }
        });
    onlineNearByAvailbleDriversList =
        GeofireAssistant.activeNearByAvailbleDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);
  }

  searchNearestOnlineDrivers(String selectedVehicleType) async {
    if (onlineNearByAvailbleDriversList.length == 0) {
      referenceRideRequest!.remove();
      setState(() {
        polyLineSet.clear();
        markersSet.clear();
        circleSet.clear();
        polyLineCoordinatesList.clear();
      });
      Fluttertoast.showToast(msg: "No Online nearest Drivers Availble");
      Fluttertoast.showToast(msg: "Search Again. \n Restarting app.");
      Future.delayed(Duration(milliseconds: 4000), () {
        referenceRideRequest!.remove();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => SplashScreen()),
        );
      });
      return;
    }
    await retrieveOnlineDriversInformation(onlineNearByAvailbleDriversList);

    print("Driver List;" + driversList.toString());
    for (int i = 0; i < driversList.length; i++) {
      if (driversList[i]["car_details"]["type"] == selectedVehicleType) {
        AssistentMethod.sendNotificationToDriverNow(
          driversList[i]["token"],
          referenceRideRequest!.key!,
          context,
        );
      }
    }
    Fluttertoast.showToast(msg: "Notification send successfully");
    showSearchingForDriversContainer();
    await FirebaseDatabase.instance
        .ref()
        .child("All Ride Reqeasts")
        .child(referenceRideRequest!.key!)
        .child("driverId")
        .onValue
        .listen((eventRideRequeastSnapshot) {
          print("EventSnapshot:${eventRideRequeastSnapshot.snapshot.value}");
          if (eventRideRequeastSnapshot.snapshot.value != null) {
            if (eventRideRequeastSnapshot.snapshot.value != "waiting") {
              showUIForAssignedDriverInfo();
            }
          }
        });
  }

  showUIForAssignedDriverInfo() {
    waitingResponcefrommDriverHeight = 200;
    searchLocationContainerHeight = 0;
    assignDriverInfoContainerHeight = 200;
    suggestedRideContainerHeight = 0;
    bottomPaddingOfMap = 200;
  }

  updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng) async {
    if (requestPositionInfo = true) {
      requestPositionInfo = false;
      LatLng userPickUpLocation = LatLng(
        userCurrentPosition!.latitude,
        userCurrentPosition!.longitude,
      );
      var directionDetsilsInfo =
          await AssistentMethod.obtainOriginToDestinationDirectionDetails(
            driverCurrentPositionLatLng,
            userPickUpLocation,
          );
      if (directionDetsilsInfo == null) {
        return;
      }
      setState(() {
        driverRideStatus =
            "Driver is coming:" + directionDetsilsInfo.distanceText.toString();
      });
    }
  }

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if (requestPositionInfo = true) {
      requestPositionInfo = false;
      var dropOffLocation = Provider.of<AppInfo>(
        context,
        listen: false,
      ).userDropOffLocation;
      LatLng userDestinationPosition = LatLng(
        dropOffLocation!.locationLatitude!,
        dropOffLocation.locationLongitude!,
      );
      var directionDetailsInfo =
          await AssistentMethod.obtainOriginToDestinationDirectionDetails(
            driverCurrentPositionLatLng,
            userDestinationPosition,
          );
      if (directionDetailsInfo == null) {
        return;
      }
      setState(() {
        driverRideStatus =
            "Going Towards Destination:" +
            directionDetailsInfo.durationText.toString();
      });
      requestPositionInfo = true;
    }
  }

  retrieveOnlineDriversInformation(List onlineNearestDriversList) async {
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");
    for (int i = 0; i < onlineNearestDriversList.length; i++) {
      await ref
          .child(onlineNearestDriversList[i].driverId.toString())
          .once()
          .then((dataSnapshot) {
            var driverKeyInfo = dataSnapshot.snapshot.value;
            driversList.add(driverKeyInfo);
            print("driver key information=" + driversList.toString());
          });
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 50, 10, 10),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: darkTheme ? Colors.black87 : Colors.white,
                    borderRadius: BorderRadius.only(
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
                            await drawPolyLineFromOriginToDestination(
                              darkTheme,
                            );
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                var result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) =>
                                        PecisePickupLocationScreen(),
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
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Change Pick Up ",
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
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (Provider.of<AppInfo>(
                                      context,
                                      listen: false,
                                    ).userDropOffLocation !=
                                    null) {
                                  showSuggestedRideContainer();
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "Please select destination locations",
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkTheme
                                    ? Colors.amber
                                    : Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Show Fare",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: darkTheme
                                      ? Colors.black
                                      : Colors.white,
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
            ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Container(
                height: suggestedRideContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: darkTheme
                                    ? Colors.amber.shade400
                                    : Colors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(Icons.stars, color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                Provider.of<AppInfo>(
                                      context,
                                    ).userPickUpLocation?.locationName ??
                                    "Getting current location...",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: darkTheme
                                    ? Colors.amber.shade400
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(Icons.stars, color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                Provider.of<AppInfo>(
                                      context,
                                    ).userDropOffLocation?.locationName ??
                                    "Where to?",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          "SUGGESTED RIDES",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicleType = "Car";
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedVehicleType == "Car"
                                        ? (darkTheme
                                              ? Colors.amber.shade400
                                              : Colors.blue)
                                        : (darkTheme ? Colors.black54 : Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          "assets/car.webp",
                                          scale: 2.5,
                                          height: 50,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Car",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selectedVehicleType == "Car"
                                                ? (darkTheme
                                                      ? Colors.black
                                                      : Colors.white)
                                                : (darkTheme
                                                      ? Colors.white
                                                      : Colors.black),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          tripDirectionDetailsInfo != null
                                              ? "₹${((AssistentMethod.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 2) * 107).toStringAsFixed(1)}"
                                              : "null",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicleType = "CNG";
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedVehicleType == "CNG"
                                        ? (darkTheme
                                              ? Colors.amber.shade400
                                              : Colors.blue)
                                        : (darkTheme ? Colors.black54 : Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          "assets/cngc.webp",
                                          scale: 2.5,
                                          height: 50,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "CNG",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selectedVehicleType == "CNG"
                                                ? (darkTheme
                                                      ? Colors.black
                                                      : Colors.white)
                                                : (darkTheme
                                                      ? Colors.white
                                                      : Colors.black),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          tripDirectionDetailsInfo != null
                                              ? "₹${((AssistentMethod.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 2) * 107).toStringAsFixed(1)}"
                                              : "null",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicleType = "Bike";
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedVehicleType == "Bike"
                                        ? (darkTheme
                                              ? Colors.amber.shade400
                                              : Colors.blue)
                                        : (darkTheme ? Colors.black54 : Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          "assets/bike.png",
                                          scale: 2.5,
                                          height: 50,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Bike",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selectedVehicleType == "Bike"
                                                ? (darkTheme
                                                      ? Colors.black
                                                      : Colors.white)
                                                : (darkTheme
                                                      ? Colors.white
                                                      : Colors.black),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          tripDirectionDetailsInfo != null
                                              ? "₹${((AssistentMethod.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 2) * 107).toStringAsFixed(1)}"
                                              : "null",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            if (selectedVehicleType != "") {
                              saveRideRequestInformation(selectedVehicleType);
                            } else {
                              Fluttertoast.showToast(
                                msg:
                                    "Please select a vehicle from \n suggested ride.",
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: darkTheme
                                  ? Colors.amber.shade400
                                  : Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "Request a Ride",
                                style: TextStyle(
                                  color: darkTheme ? Colors.black : Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: serchingForDriverContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Searching for a driver...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          referenceRideRequest!.remove();
                          setState(() {
                            serchingForDriverContainerHeight = 0;
                            suggestedRideContainerHeight = 0;
                          });
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: darkTheme ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1, color: Colors.grey),
                          ),
                          child: Icon(Icons.close, size: 25),
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        child: Text(
                          "Cancel",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
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