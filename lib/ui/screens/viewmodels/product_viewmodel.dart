import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_mobile_app/data/models/product_model.dart';
import 'package:my_mobile_app/data/repositories/product_repository.dart';
import 'package:my_mobile_app/data/services/cloudinary_service.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;
  final CloudinaryService _cloudinaryService;

  ProductViewModel({
    required ProductRepository productRepository,
    required CloudinaryService cloudinaryService,
  })  : _productRepository = productRepository,
        _cloudinaryService = cloudinaryService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<ProductModel>> get products => _productRepository.getProducts();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> saveProduct({
    String? id,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    XFile? image,
    String? existingImageUrl,
    DateTime? createdAt,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      String imageUrl = existingImageUrl ?? '';

      if (image != null) {
        final uploadedUrl = await _cloudinaryService.uploadImage(
          image,
          folder: 'shopify/products',
        );
        if (uploadedUrl.isEmpty) {
          _setError('Failed to upload product image.');
          return false;
        }
        imageUrl = uploadedUrl;
      }

      final product = ProductModel(
        id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        category: category,
        stock: stock,
        createdAt: createdAt ?? DateTime.now(),
      );

      if (id == null) {
        await _productRepository.addProduct(product);
      } else {
        await _productRepository.updateProduct(product);
      }

      return true;
    } catch (e) {
      _setError('Failed to save product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      _setLoading(true);
      _setError(null);
      await _productRepository.addProduct(product);
      return true;
    } catch (e) {
      _setError('Failed to add product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      _setLoading(true);
      _setError(null);
      await _productRepository.updateProduct(product);
      return true;
    } catch (e) {
      _setError('Failed to update product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _setError(null);
      await _productRepository.deleteProduct(productId);
      return true;
    } catch (e) {
      _setError('Failed to delete product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
