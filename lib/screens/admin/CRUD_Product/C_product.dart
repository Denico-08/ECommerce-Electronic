// ignore_for_file: unnecessary_null_comparison

import 'package:google_fonts/google_fonts.dart';
import 'package:KlikGadget/screens/admin/CRUD_Product/RD_product.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InsertBarang extends StatefulWidget {
  const InsertBarang({super.key});

  @override
  State<InsertBarang> createState() => _InsertBarangState();
}

class _InsertBarangState extends State<InsertBarang> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;
  String? _selectedCategory;
  final List<String> _categoryItems = [
    "HP",
    "Tablet",
    "TV",
    "Radio",
    "Laptop",
  ];

  final ImagePicker _picker = ImagePicker();

  Future<String?> _uploadImage() async {
    final user = Supabase.instance.client.auth.currentUser;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || user == null) {
      _showSnackbar('No image selected or user not authenticated.');
      return null;
    }

    try {
      final fileExt = pickedFile.name.split('.').last.toLowerCase();
      final fileName =
          'product_images/${user.id}.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final imageBytes = await pickedFile.readAsBytes();

      if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExt)) {
        throw Exception('Unsupported image format');
      }

      if (_imageUrl != null) {
        final existingFileName = _imageUrl!.split('/').last;
        await Supabase.instance.client.storage
            .from('product_images')
            .remove([existingFileName]);
      }

      final response = await Supabase.instance.client.storage
          .from('product_images')
          .uploadBinary(fileName, imageBytes);

      if (response != null) {
        final publicUrl = Supabase.instance.client.storage
            .from('product_images')
            .getPublicUrl(fileName);

        setState(() {
          _imageUrl = publicUrl;
        });

        return _imageUrl;
      } else {
        _showSnackbar('Error uploading image: $response');
      }
    } catch (e) {
      _showSnackbar('Unexpected error occurred: $e');
    }

    return null;
  }

  Future<void> _insertData() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final price = int.tryParse(_priceController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final description = _descriptionController.text;

    if (name.isEmpty ||
        price <= 0 ||
        quantity <= 0 ||
        _selectedCategory == null ||
        description.isEmpty) {
      _showSnackbar('Please fill in all fields correctly.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final insertResponse =
          await Supabase.instance.client.from('product').insert({
        'name': name,
        'description': description,
        'price': price,
        'category': _selectedCategory,
        'stock': quantity,
        'imageurl': _imageUrl,
      }).single();

      if (insertResponse != null) {
        _showSnackbar('Product successfully added.');
      } else {
        _showSnackbar('Error inserting data: $insertResponse');
      }
    } catch (e) {
      _showSnackbar('Produk berhasil dimasukkan.');

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Admin_Barang()));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tambah Data Barang',
          style: GoogleFonts.lato(color: Color.fromRGBO(41, 68, 135, 1)),
        ),
      ),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _uploadImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                  child: _imageUrl == null
                      ? const Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama barang tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Kuantitas'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kuantitas tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
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
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _insertData();
                        }
                      },
                      child: const Text('Insert'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
