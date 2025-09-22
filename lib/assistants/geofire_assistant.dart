import 'package:flutter/cupertino.dart';
import 'package:our_cabss/models/active_nearby_availble_drivers.dart';

class GeofireAssistant {
  static List<ActiveNearByAvailbleDrivers> activeNearByAvailbleDriversList = [];
  static void deleteOfflineDriverFromList(String driverId) {
    int indexNumber = activeNearByAvailbleDriversList.indexWhere(
      (element) => element.driverId == driverId,
    );
  }

  static void updateNearByAvailbleDriverLocation(
    ActiveNearByAvailbleDrivers driverWhoMove,
  ) {
    int indexNumber = activeNearByAvailbleDriversList.indexWhere(
      (element) => element.driverId == driverWhoMove.driverId,
    );
    activeNearByAvailbleDriversList[indexNumber].locationLatitde =
        driverWhoMove.locationLatitde;
    activeNearByAvailbleDriversList[indexNumber].locationLongitude =
        driverWhoMove.locationLatitde;
        
  }
}
