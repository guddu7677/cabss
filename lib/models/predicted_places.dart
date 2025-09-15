class PredictedPlaces {
  String? secondaryText;
  String? mainText;
  String? placeId;

  PredictedPlaces({this.mainText, this.placeId, this.secondaryText});
PredictedPlaces.fromJson(Map<String, dynamic> json) {
    mainText = json["structured_formatting"]["main_text"];
    placeId = json["place_id"];
    secondaryText = json["structured_formatting"]["secondary_text"];
  }

}