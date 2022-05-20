import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier{
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
  });

  void _setFavValue(bool newValue) {
    isFavorite = newValue;
    notifyListeners();
  }

  Future<void> toggleFavoriteStatus(String token, String userId) async {
    final oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();
    final url = "https://shop-app-976f4-default-rtdb.firebaseio.com/userFavorites/$userId/$id.json?auth=$token";
    try{
      final responce = await http.put(Uri.parse(url), body: json.encode(
        isFavorite,
      ));
      if(responce.statusCode >= 400) {
        _setFavValue(oldStatus);
        // isFavorite = oldStatus;
        // notifyListeners();
      }
    } catch (error) {
      _setFavValue(oldStatus);
      // isFavorite = oldStatus;
      // notifyListeners();
    }
  }
}
