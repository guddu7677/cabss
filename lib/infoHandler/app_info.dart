import 'package:flutter/material.dart';
import 'package:our_cabss/models/direction.dart';

class AppInfo extends ChangeNotifier {
  Directions? userDropOffLocation;
  Directions? userPickUpLocation;
  int? countTotalTrips = 0;
  // List<String> historyTripsKeys = [];
  // List<TripHistoryModel> allTripsHistoryInformation = [];

void UpdatePickUpLocationAddress(Directions userPickUpAddress) {
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }

  void UpdateDropOffLocationAddress(Directions userDropOffAddress) {
    userDropOffLocation = userDropOffAddress;
    notifyListeners();
  }

  void updateTotalTripsCounter(int totalTrips) {
    countTotalTrips = totalTrips;
    notifyListeners();
  }

  // void updateTripKeys(List<String> tripKeys) {
  //   historyTripsKeys = tripKeys;
  //   notifyListeners();
  // }

  // void updateAllTripsHistoryInformation(
  //     List<TripHistoryModel> allTripsHistory) {
  //   allTripsHistoryInformation = allTripsHistory;
  //   notifyListeners();
  // }

}
