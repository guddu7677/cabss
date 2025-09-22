import 'package:flutter/material.dart';
import 'package:our_cabss/assistants/request_assistant.dart';
import 'package:our_cabss/infoHandler/app_info.dart';
import 'package:our_cabss/models/direction.dart';
import 'package:our_cabss/models/predicted_places.dart';
import 'package:our_cabss/services/map_key.dart';
import 'package:provider/provider.dart';

class PlacePredictionTileDesion extends StatelessWidget {
  final PredictedPlaces? predictedPlaces;

  const PlacePredictionTileDesion({
    Key? key, 
    this.predictedPlaces,
  }) : super(key: key);

  Future<void> getPlaceDirectionDetails(String? placeId, BuildContext context) async {
    if (placeId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String placeDirectionsDetailsUrl = 
          "https://maps.googleapis.com/maps/api/place/details/json?"
          "place_id=$placeId&key=$mapKey";

      var responseApi = await RequestAssistant.receiveRequest(placeDirectionsDetailsUrl);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (responseApi == "Error Occurred, Failed. No Response.") {
        _showErrorSnackBar(context, "Failed to get place details");
        return;
      }

      if (responseApi["status"] == "OK") {
        Directions directions = Directions();
        directions.locationId = placeId;
        directions.locationName = responseApi["result"]["name"];
        directions.locationLatitude = responseApi["result"]["geometry"]["location"]["lat"];
        directions.locationLongitude = responseApi["result"]["geometry"]["location"]["lng"];

        Provider.of<AppInfo>(context, listen: false)
            .updateDropOffLocationAddress(directions);

        Navigator.pop(context, "obtainedDropOff");
      } else {
        _showErrorSnackBar(context, "Place not found");
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar(context, "Error getting place details");
      print("Error getting place details: $e");
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        onTap: () {
          getPlaceDirectionDetails(predictedPlaces?.placeId, context);
        },
        leading: Icon(
          Icons.add_location,
          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
          size: 24,
        ),
        title: Text(
          predictedPlaces?.mainText ?? "Unknown Place",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: darkTheme ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: predictedPlaces?.secondaryText != null
            ? Text(
                predictedPlaces!.secondaryText!,
                style: TextStyle(
                  fontSize: 12,
                  color: darkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: darkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 16,
        ),
      ),
    );
  }
}
