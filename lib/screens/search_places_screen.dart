import 'package:flutter/material.dart';
import 'package:our_cabss/assistants/request_assistant.dart';
import 'package:our_cabss/models/predicted_places.dart';
import 'package:our_cabss/services/map_key.dart';
import 'package:our_cabss/widgets/place_prediction_tile.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  List<PredictedPlaces> placePredictionsList = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  Future<void> findPlaceAutoCompleteSearch(String inputText) async {
    if (inputText.length > 1) {
      setState(() {
        isLoading = true;
      });

      try {
        String urlAutoCompleteSearch = 
            "https://maps.googleapis.com/maps/api/place/autocomplete/json?"
            "input=${Uri.encodeComponent(inputText)}&key=$mapKey&components=country:in";

        var responseAutoCompleteSearch = 
            await RequestAssistant.receiveRequest(urlAutoCompleteSearch);
        
        setState(() {
          isLoading = false;
        });

        if (responseAutoCompleteSearch == "Error Occurred, Failed. No Response.") {
          setState(() {
            placePredictionsList.clear();
          });
          return;
        }

        if (responseAutoCompleteSearch["status"] == "OK") {
          var placePredictions = responseAutoCompleteSearch["predictions"];
          var newPlacePredictionsList = (placePredictions as List)
              .map((jsonData) => PredictedPlaces.fromJson(jsonData))
              .toList();
          
          setState(() {
            placePredictionsList = newPlacePredictionsList;
          });
        } else {
          setState(() {
            placePredictionsList.clear();
          });
        }
      } catch (e) {
        setState(() {
          isLoading = false;
          placePredictionsList.clear();
        });
        print("Error in search: $e");
      }
    } else {
      setState(() {
        placePredictionsList.clear();
        isLoading = false;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(
          "Search & Set Drop Off Location",
          style: TextStyle(
            color: isDark ? Colors.amber.shade400 : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.amber.shade400 : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Input Container
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.amber.shade400 : Colors.blue,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: const Offset(0.7, 0.7),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          findPlaceAutoCompleteSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: "Search places...",
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          suffixIcon: isLoading
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  padding: const EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? Colors.amber.shade400 : Colors.blue,
                                    ),
                                  ),
                                )
                              : searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {
                                          placePredictionsList.clear();
                                        });
                                      },
                                    )
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Results List
          Expanded(
            child: placePredictionsList.isNotEmpty
                ? ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      return PlacePredictionTileDesion(
                        predictedPlaces: placePredictionsList[index],
                      );
                    },
                    itemCount: placePredictionsList.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          color: isDark 
                              ? Colors.amber.shade400.withOpacity(0.3) 
                              : Colors.blue.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      );
                    },
                  )
                : searchController.text.isNotEmpty && !isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No places found. Try a different search term.",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Start typing to search for places",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
