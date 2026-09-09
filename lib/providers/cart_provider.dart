import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/cart_model.dart';
import '../data/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingItem) => CartItemModel(
          id: existingItem.id,
          productId: existingItem.productId,
          productName: existingItem.productName,
          price: existingItem.price,
          imageUrl: existingItem.imageUrl,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItemModel(
          id: const Uuid().v4(),
          productId: product.id,
          productName: product.name,
          price: product.price,
          imageUrl: product.imageUrl,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingItem) => CartItemModel(
          id: existingItem.id,
          productId: existingItem.productId,
          productName: existingItem.productName,
          price: existingItem.price,
          imageUrl: existingItem.imageUrl,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    _items.update(
      productId,
      (existingItem) => CartItemModel(
        id: existingItem.id,
        productId: existingItem.productId,
        productName: existingItem.productName,
        price: existingItem.price,
        imageUrl: existingItem.imageUrl,
        quantity: existingItem.quantity + 1,
      ),
    );
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
