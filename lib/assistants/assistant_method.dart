import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:our_cabss/assistants/request_assistant.dart';
import 'package:our_cabss/infoHandler/app_info.dart';
import 'package:our_cabss/models/direction.dart';
import 'package:our_cabss/models/direction_details_info.dart';
import 'package:our_cabss/models/user_model.dart';
import 'package:our_cabss/services/auth_serviece.dart';
import 'package:our_cabss/services/map_key.dart';
import 'package:provider/provider.dart';

class AssistentMethod {
  static void readCurrentOnlineUserInfo() async {
    try {
      currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child("users")
            .child(currentUser!.uid);

        DatabaseEvent event = await userRef.once();
        if (event.snapshot.value != null) {
          userModelCurrentInfo = UserModel.fromSnapshot(event.snapshot);
        }
      }
    } catch (e) {
      print("Error reading user info: $e");
    }
  }

  static Future<String> searchAddressForGeographicCoordinated(
    Position position,
    context,
  ) async {
    String apiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?"
        "latlng=${position.latitude},${position.longitude}&key=$mapKey";

    String humanReadableAddress = "";

    try {
      var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

      if (requestResponse != "Error Occurred, Failed. No Response.") {
        if (requestResponse["results"] != null &&
            requestResponse["results"].isNotEmpty) {
          humanReadableAddress =
              requestResponse["results"][0]["formatted_address"];

          Directions userPickUpAddress = Directions();
          userPickUpAddress.locationLatitude = position.latitude;
          userPickUpAddress.locationLongitude = position.longitude;
          userPickUpAddress.locationName = humanReadableAddress;

          Provider.of<AppInfo>(
            context,
            listen: false,
          ).updatePickUpLocationAddress(userPickUpAddress);
        }
      }
    } catch (e) {
      print("Error in searchAddressForGeographicCoordinated: $e");
    }

    return humanReadableAddress;
  }

  static Future<DirectionDetailsInfo?>
  obtainOriginToDestinationDirectionDetails(
    LatLng originLatLng,
    LatLng destinationLatLng,
  ) async {
    String UrlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${originLatLng.latitude},${originLatLng.longitude}"
        "&destination=${destinationLatLng.latitude},${destinationLatLng.longitude}"
        "&key=$mapKey";

    var responseDirectionApi = await RequestAssistant.receiveRequest(
      UrlOriginToDestinationDirectionDetails,
    );

    if (responseDirectionApi == "Error Occurred, Failed. No Response.") {
      return null;
    }

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.durationText =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.durationValue =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];
    directionDetailsInfo.distanceText =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distanceValue =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];
    directionDetailsInfo.encodedPoints =
        responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    return directionDetailsInfo;
  }

  static double calculateFareAmountFromOriginToDestination(
    DirectionDetailsInfo directionDetailsInfo,
  ) {
    double timeTraveledFareAmountPerMinute =
        (directionDetailsInfo.durationValue! / 60) * 0.1;
    double distanceTraveledFareAmountPerKilometer =
        (directionDetailsInfo.durationValue! / 1000) * 0.1;
    double totalFareAmount =
        timeTraveledFareAmountPerMinute +
        distanceTraveledFareAmountPerKilometer;
    return double.parse(totalFareAmount.toStringAsFixed(1));
  }

  static sendNotificationToDriverNow(
    String deviceRegistrationToken,
    String userRideRequestId,
    context,
  ) async {
    String destinationAddress = userDropOffAddress!;
    Map<String, String> headerNotification = {
      'content_type': "application/json",
      'Authorization': claudMessagingServerToken,
    };
    Map bodyNotification = {
      'body': "Destination Address:\n$destinationAddress",
      "title": "New Trip Request",
    };
    Map dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "rideRequestId": userRideRequestId,
    };
    Map officialNotificationFormat = {
      "notification": bodyNotification,
      "data": dataMap,
      "priority": "high",
      "to": deviceRegistrationToken,
    };
    var responceNotifiation = http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headerNotification,
      body: jsonEncode(officialNotificationFormat),
    );
  }
}
