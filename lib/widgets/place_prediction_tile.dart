import 'package:flutter/material.dart';
import 'package:our_cabss/assistents/request_assistent.dart';
import 'package:our_cabss/infoHandler/app_info.dart';
import 'package:our_cabss/models/direction.dart';
import 'package:our_cabss/models/predicted_places.dart';
import 'package:our_cabss/services/map_key.dart';
import 'package:provider/provider.dart';

class PlacePredictionTileDesion extends StatelessWidget {
  final PredictedPlaces? predictedPlaces;

  const PlacePredictionTileDesion({Key? key, this.predictedPlaces}) : super(key: key);

  getPlaceDirectionDetails(String? placeId, BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    String placeDirectionsDetailsUrl = 
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var responseApi = await RequestAssistant.receiveRequest(placeDirectionsDetailsUrl);

    Navigator.pop(context); // Close loading dialog

    if (responseApi == "Error Occurred, Failed. No Response.") {
      return;
    }

    if (responseApi["status"] == "OK") {
      Directions directions = Directions();
      directions.locationId = placeId;
      directions.locationName = responseApi["result"]["name"];
      directions.locationLatitude = responseApi["result"]["geometry"]["location"]["lat"];
      directions.locationLongitude = responseApi["result"]["geometry"]["location"]["lng"];

      Provider.of<AppInfo>(context, listen: false).updateDropOffLocationAddress(directions);

      Navigator.pop(context, "obtainedDropOff");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return ElevatedButton(
      onPressed: () {
        getPlaceDirectionDetails(predictedPlaces!.placeId, context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: darkTheme ? Colors.grey.shade800 : Colors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Container(
        padding:  EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.add_location,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              size: 24,
            ),
             SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    predictedPlaces!.mainText ?? "",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: darkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    predictedPlaces!.secondaryText ?? "",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12,
                      color: darkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: darkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}