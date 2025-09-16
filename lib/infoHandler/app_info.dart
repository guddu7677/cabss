import 'package:flutter/foundation.dart';
import 'package:our_cabss/models/direction.dart';

class AppInfo extends ChangeNotifier {
  Directions? userPickUpLocation;
  Directions? userDropOffLocation;

  void updatePickUpLocationAddress(Directions userPickUpAddress) {
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Directions userDropOffLocationAddress) {
    userDropOffLocation = userDropOffLocationAddress;
    notifyListeners();
  }

  void clearDropOffLocation() {
    userDropOffLocation = null;
    notifyListeners();
  }
}