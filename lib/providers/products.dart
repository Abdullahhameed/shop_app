import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';
import 'product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  // var _showFavoritesOnly = false;
  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    // if(_showFavoritesOnly){
    //   return _items.where((prodItem) => prodItem.isFavorite).toList();
    // }
    return [..._items];
  }

  List<Product> get favoriteItem {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url =
        'https://shop-app-976f4-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url =
      'https://flutter-update.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
      final favoriteResponse = await http.get(Uri.parse(url));
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          isFavorite:
          favoriteData == null ? false : favoriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  // Future<void> fetchAndSetProducts([bool filterByUser = true]) async {
  //
  //   final filterString = filterByUser ? "orderBy=creatorId&equalTo=$userId" : '';
  //   var url = "https://shop-app-976f4-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString";
  //   print('sstart');
  //   print(url);
  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     final extractedData = json.decode(response.body) as Map<String, dynamic>;
  //     if (extractedData == null) {
  //       return;
  //     }
  //     url = "https://shop-app-976f4-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken";
  //     final favoriteResponce =  await http.get(Uri.parse(url));
  //     final favoriteData = json.decode(favoriteResponce.body);
  //     final List<Product> loadedProducts = [];
  //     extractedData.forEach((prodId, prodData) {
  //       loadedProducts.add(Product(
  //         id: prodId,
  //         title: prodData['title'],
  //         description: prodData['description'],
  //         price: prodData['price'],
  //         isFavorite: favoriteData == null ? false : favoriteData[prodId] ?? false,
  //         imageUrl: prodData['imageUrl'],
  //       ));
  //     });
  //     _items = loadedProducts;
  //     notifyListeners();
  //   } catch (error) {
  //     throw (error);
  //   }
  // }

  // Future<void> addProduct(Product product) {
  Future<void> addProduct(Product product) async {

      final url = "https://shop-app-976f4-default-rtdb.firebaseio.com/products.json?auth=$authToken";
      // return http.post(
      try {
        final responce = await http.post(
          Uri.parse(url),
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
            'creatorId' : userId,
            // 'isFavorite': product.isFavorite,
          }),
        );

        final newProduct = Product(
            title: product.title,
            description: product.description,
            price: product.price,
            imageUrl: product.imageUrl,
            id: json.decode(responce.body)['name']
          // id: DateTime.now().toString(),
        );

        _items.add(newProduct);
        notifyListeners();
      } catch (error) {
        print(error);
        throw error;
      }
    }

    Future<void> updateProduct(String id, Product newProduct) async {
      final prodIndex = _items.indexWhere((prod) => prod.id == id);
      if (prodIndex >= 0) {
        final url = "https://shop-app-976f4-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken";
        await http.patch(Uri.parse(url), body: json.encode({
          'title' : newProduct.title,
          'description' : newProduct.description,
          'price' : newProduct.price,
          // 'isFavorite' : newProduct.isFavorite,
          'imageUrl' : newProduct.imageUrl
        }),);
        _items[prodIndex] = newProduct;
        notifyListeners();
      } else {
        print('...');
      }
    }

    Future<void> deleteProduct(String id) async {
      final url = "https://shop-app-976f4-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken";
      final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
      var existingProduct = _items[existingProductIndex];
      _items.removeAt(existingProductIndex);
      notifyListeners();
      // _items.removeWhere((prod) => prod.id == id);
      final responce = await http.delete(Uri.parse(url));
      if(responce.statusCode >= 400) {
         _items.insert(existingProductIndex, existingProduct);
         notifyListeners();
         throw HttpException('Could not delete Product');
      }
      existingProduct == null;
    }

}
