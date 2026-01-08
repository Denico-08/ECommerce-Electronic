import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:KlikGadget/main.dart';

class UpdateBarang extends StatefulWidget {
  final String productId;

  const UpdateBarang({super.key, required this.productId});

  @override
  State<UpdateBarang> createState() => _UpdateBarangState();
}

class _UpdateBarangState extends State<UpdateBarang> {
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _product;
  int? _price;
  String? _category;
  int? _quantity;
  String? _description;
  String? _imageUrl; // To store the image URL
  String? _selectedCategory;
  final List<String> _categoryItems = [
    "HP",
    "Tablet",
    "TV",
    "Radio",
    "Laptop",
  ];

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      final productData = await supabase
          .from('product')
          .select('*') // Select all columns
          .eq('id', widget.productId) // Filter by product ID
          .single(); // Expect a single row

      setState(() {
        _product = productData['name'] ?? '';
        _price = productData['price'] ?? 0;
        _category = productData['category'] ?? '';
        _quantity = productData['stock'] ?? 0;
        _description = productData['description'] ?? '';
        _imageUrl = productData['imageurl'] ?? '';
        _productController.text = _product!;
        _priceController.text = _price.toString();
        _categoryController.text = _category!;
        _quantityController.text = _quantity.toString();
        _descriptionController.text = _description!;
      });
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading product data: ${error.message}')),
        );
      }
    } catch (error) {
      print('Error loading product data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load product data')),
        );
      }
    }
  }

  Future<void> _updateProductData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updates = {
        'name': _productController.text,
        'price': int.tryParse(_priceController.text) ?? 0,
        'category': _categoryController.text,
        'stock': int.tryParse(_quantityController.text) ?? 0,
        'description': _descriptionController.text,
        'imageurl': _imageUrl,
      };

      final result = await supabase
          .from('product')
          .update(updates)
          .eq('id', widget.productId);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error updating product: ${result.error!.message}')),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: ${error.message}')),
        );
      }
    } catch (error) {
      print('Error updating product: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Success Update')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      try {
        // Get the file extension
        final fileExt = pickedFile.name.split('.').last.toLowerCase();
        final fileName = 'product_images/${widget.productId}.$fileExt';

        // Read the image data as bytes
        final imageBytes = await pickedFile.readAsBytes();

        // Validate file extension
        const supportedFormats = ['jpg', 'jpeg', 'png', 'gif'];
        if (!supportedFormats.contains(fileExt)) {
          throw Exception('Unsupported image format');
        }

        // Delete the existing image file with the same name from storage
        try {
          await supabase.storage.from('product_images').remove([fileName]);
        } catch (e) {
          // If the file doesn't exist, we simply continue.
          print('No existing file found to delete');
        }

        // Upload the new image
        final response = await supabase.storage
            .from('product_images')
            .uploadBinary(fileName, imageBytes,
                fileOptions: FileOptions(contentType: 'image/$fileExt'));

        // Check if the upload was successful
        if (response != null) {
          // Set the new image URL
          final newImageUrl =
              supabase.storage.from('product_images').getPublicUrl(fileName);
          setState(() {
            _imageUrl = newImageUrl;
          });

          // Update the product data with the new image URL
          await _updateProductData();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error uploading image')),
            );
          }
        }
      } on PostgrestException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Postgrest Error: ${e.message}')),
          );
        }
      } catch (e) {
        print('Unexpected error during image upload: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Success Update Image')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

// Function to remove the image URL from the database
  Future<void> _removeImageUrlFromDatabase() async {
    try {
      // Example logic: Update the product record and set the image URL to null or empty
      await supabase
          .from('product') // Update with your table name
          .update({'imageurl': null}) // Set image_url field to null
          .eq('id', widget.productId); // Use your product identifier
    } catch (e) {
      print('Error removing image URL from database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Product')),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _uploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                child: _imageUrl == null
                    ? const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _productController,
              decoration: const InputDecoration(labelText: 'Product'),
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButton<String>(
              hint: const Text("Category"),
              value: _selectedCategory,
              items: _categoryItems.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProductData,
              child: Text(_isLoading ? 'Updating...' : 'Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}
