import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestAssistant {
  static Future<dynamic> receiveRequest(String url) async {
    try {
      http.Response response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        String responseData = response.body;
        var decodeResponseData = jsonDecode(responseData);
        return decodeResponseData;
      } else {
        print("HTTP Error: ${response.statusCode}");
        return "Error Occurred, Failed. No Response.";
      }
    } catch (e) {
      print("Request Error: $e");
      return "Error Occurred, Failed. No Response.";
    }
  }
}