import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:my_mobile_app/data/models/product_model.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/product_viewmodel.dart';

// We import dart:io only for mobile Image.file
import 'dart:io' as io;

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  XFile? _selectedXFile;
  String? _existingImageUrl;
  String _category = 'Electronics';

  final List<String> categories = [
    'Electronics', 'Clothing', 'Shoes', 'Food', 'Beauty', 'Home', 'Books', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    _stockController = TextEditingController(text: product?.stock.toString() ?? '');
    _existingImageUrl = product?.imageUrl;

    if (product != null && categories.contains(product.category)) {
      _category = product.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
      if (image == null) return;
      setState(() {
        _selectedXFile = image;
        _existingImageUrl = null;
      });
    } catch (e) {
      _showMessage('Failed to select image: $e', isError: true);
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choose from Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take a Photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            if (_selectedXFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
              ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Remove Image'), onTap: () { Navigator.pop(context); setState(() { _selectedXFile = null; _existingImageUrl = null; }); }),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (price == null || stock == null) {
      _showMessage('Enter valid price and stock.', isError: true);
      return;
    }

    if (!widget.isEditing && _selectedXFile == null) {
      _showMessage('Please select an image.', isError: true);
      return;
    }

    final viewModel = context.read<ProductViewModel>();
    final success = await viewModel.saveProduct(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: price,
      category: _category,
      stock: stock,
      image: _selectedXFile,
      existingImageUrl: _existingImageUrl,
      createdAt: widget.product?.createdAt,
    );

    if (!mounted) return;

    if (success) {
      _showMessage(widget.isEditing ? 'Updated successfully' : 'Added successfully');
      Navigator.pop(context);
    } else {
      _showMessage(viewModel.errorMessage ?? 'Failed to save.', isError: true);
    }
  }

  void _showMessage(String m, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: isError ? Colors.red : null));
  }

  Widget _buildImagePreview() {
    if (_selectedXFile != null) {
      return kIsWeb 
        ? Image.network(_selectedXFile!.path, width: double.infinity, height: 220, fit: BoxFit.cover)
        : Image.file(io.File(_selectedXFile!.path), width: double.infinity, height: 220, fit: BoxFit.cover);
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Image.network(_existingImageUrl!, width: double.infinity, height: 220, fit: BoxFit.cover, errorBuilder: (_, index, stack) => _emptyImageWidget());
    }
    return _emptyImageWidget();
  }

  Widget _emptyImageWidget() {
    return Container(height: 220, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_outlined, size: 60, color: Colors.grey), SizedBox(height: 10), Text('No image selected', style: TextStyle(color: Colors.grey))]));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProductViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Update Product' : 'Add Product')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Product Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(12), child: _buildImagePreview()),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: OutlinedButton.icon(onPressed: viewModel.isLoading ? null : _showImageSourceOptions, icon: const Icon(Icons.add_a_photo), label: const Text('Choose Image'))), if (_selectedXFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)) ...[const SizedBox(width: 10), IconButton(onPressed: viewModel.isLoading ? null : () => setState(() { _selectedXFile = null; _existingImageUrl = null; }), icon: const Icon(Icons.delete, color: Colors.red))]]),
              const SizedBox(height: 25),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price', prefixText: 'KES ', border: OutlineInputBorder()), validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null)), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null))]),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: viewModel.isLoading ? null : (v) { if (v != null) setState(() => _category = v); }),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: viewModel.isLoading ? null : _saveProduct, icon: viewModel.isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save), label: Text(viewModel.isLoading ? 'Saving...' : (widget.isEditing ? 'Update Product' : 'Add Product')))),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
