import 'package:flutter/material.dart';
import '../data/models/product_model.dart';

class WishlistProvider with ChangeNotifier {
  final Map<String, ProductModel> _wishlistItems = {};

  Map<String, ProductModel> get wishlistItems => {..._wishlistItems};

  int get itemCount => _wishlistItems.length;

  bool isFavorite(String productId) {
    return _wishlistItems.containsKey(productId);
  }

  void toggleWishlist(ProductModel product) {
    if (_wishlistItems.containsKey(product.id)) {
      _wishlistItems.remove(product.id);
    } else {
      _wishlistItems.putIfAbsent(product.id, () => product);
    }
    notifyListeners();
  }

  void clearWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }
}
