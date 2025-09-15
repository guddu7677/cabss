import 'package:flutter/material.dart';
import 'package:our_cabss/assistents/request_assistent.dart';
import 'package:our_cabss/models/predicted_places.dart';
import 'package:our_cabss/services/map_key.dart';
import 'package:our_cabss/theme_provider/theme_provider.dart';
import 'package:our_cabss/widgets/place_prediction_tile.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  List<PredictedPlaces> placePredictionsList = [];
  TextEditingController searchController = TextEditingController();

  Future<void> findPlaceAutoCompleteSearch(String inputText) async {
    if (inputText.length > 1) {
      String UrlautoCompleteSearch="https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$inputText&key=$mapKey&components=country:in";

      var responceAuroCompleteSearch = await RequestAssistant.receiveRequest(UrlautoCompleteSearch);
      if(responceAuroCompleteSearch == "Error Occurred, Failed. No Response."){
        return;
      }
      if (responceAuroCompleteSearch["status"] == "OK") {
        var placePredictions = responceAuroCompleteSearch["predictions"];
        var placePredictionsList = (placePredictions as List).map((jsonData) => PredictedPlaces.fromJson(jsonData)).toList();
        setState(() {
          this.placePredictionsList = placePredictionsList;
        });
      }
    } else {
      setState(() {
        placePredictionsList.clear();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.primaryColor,
          title: Text(
            "Search & Set Drop Off location",
            style: TextStyle(
              color:
                  theme.appBarTheme.foregroundColor ??
                  (isDark ? Colors.amber.shade400 : Colors.blue),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          leading: GestureDetector(
            child: Icon(
              Icons.arrow_back,
              color:
                  theme.appBarTheme.foregroundColor ??
                  (isDark ? Colors.amber.shade400 : Colors.blue),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color:isDark ? Colors.amber.shade400: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : Colors.grey,
                    blurRadius: 6,
                    spreadRadius: 0.5,
                    offset: const Offset(0.7, 0.7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 10),
                        Icon(
                          Icons.adjust_sharp,
                          color: isDark ? Colors.grey[300] : Colors.grey,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              findPlaceAutoCompleteSearch(value);
                            },
                            decoration: InputDecoration(
                              hintText: "Search here...",
                              hintStyle: TextStyle(
                                color: isDark ? Colors.blue: Colors.grey,
                              ),
                              filled: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                left: 15,
                                top: 8,
                                bottom: 8,
                              ),
                            ),
                          ),
                        ),
                         SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5,),
            (placePredictionsList.length > 0)
                ? Expanded(
                    child: ListView.separated(
                      physics: ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return PlacePredictionTileDesion(
                          predictedPlaces: placePredictionsList[index],
                        );
                      },
                      itemCount: placePredictionsList.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding:  EdgeInsets.all(4.0),
                          child: Divider(
                            height: 1,
                            color: isDark ? Colors.amber.shade400 : Colors.blue,
                            thickness: 1,
                          ),
                        );
                      },
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}