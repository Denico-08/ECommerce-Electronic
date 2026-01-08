import 'package:KlikGadget/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/screens/user/Detail_product.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:KlikGadget/Model/Varian.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({
    super.key,
  });

  @override
  _FavoritePageState createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> favoriteItems = [];
  String? errorMessage;
  List<Map<String, dynamic>> cartItems = [];
  int _cartItemCount = 0;
  String? selectedColor;
  String? selectedSize;

  Future<int?> getProductVarsId(int product) async {
    try {
      final response = await supabase
          .from('product_vars')
          .select('id')
          .eq('product_id', product)
          .single();

      return response['id'];
    } catch (e) {
      print('Exception occurred while fetching product vars ID: $e');
      return null;
    }
  }

  Future<int?> insertProductVar(
      int productId,
      String category1,
      String category2,
      String category3,
      String category4,
      String category5) async {
    try {
      final response = await supabase
          .from('product_vars')
          .select('id')
          .eq('product_id', productId)
          .eq('category1', category1)
          .eq('category2', category2)
          .eq('category3', category3)
          .eq('category4', category4)
          .eq('category5', category5)
          .maybeSingle();

      if (response != null) {
        return response['id'];
      } else {
        final insertResponse = await supabase
            .from('product_vars')
            .insert({
              'product_id': productId,
              'category1': category1,
              'category2': category2,
              'category3': category3,
              'category4': category4,
              'category5': category5,
            })
            .select('id')
            .single();

        return insertResponse['id'];
      }
    } catch (e) {
      print('Error inserting product var: $e');
      return null;
    }
  }

  Future<void> addtocarts(BuildContext context, Product product,
      List<String?> selectedVariants, int _quantity) async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User is not logged in. Please log in first.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = session.user.id;

    // Pastikan setiap varian masuk ke kolom kategori yang benar
    int? productVarsId;
    try {
      final response = await supabase
          .from('product_vars')
          .insert({
            'product_id': product.id,
            'category1':
                selectedVariants.isNotEmpty ? selectedVariants[0] : null,
            'category2':
                selectedVariants.length > 1 ? selectedVariants[1] : null,
            'category3':
                selectedVariants.length > 2 ? selectedVariants[2] : null,
            'category4':
                selectedVariants.length > 3 ? selectedVariants[3] : null,
            'category5':
                selectedVariants.length > 4 ? selectedVariants[4] : null,
          })
          .select()
          .single();

      if (response != null) {
        productVarsId = response['id'];
      }
    } catch (e) {
      print('Error creating or retrieving product vars: $e');
      return;
    }

    // Tambahkan logika penambahan ke keranjang seperti sebelumnya
    try {
      final existingCartItem = await supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('product_vars_id', productVarsId as Object)
          .maybeSingle();

      if (existingCartItem != null) {
        final newQuantity = existingCartItem['quantity'] + _quantity;
        await supabase
            .from('cart_items')
            .update({'quantity': newQuantity}).eq('id', existingCartItem['id']);
      } else {
        await supabase.from('cart_items').insert({
          'product_vars_id': productVarsId,
          'quantity': _quantity,
          'user_id': userId,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${product.name} added to cart with quantity: $_quantity'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error updating or inserting into cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add item to cart.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<ProductVariant?> _fetchProductVariant(String? category) async {
    if (category == null || category.isEmpty) {
      throw Exception('Kategori tidak valid.');
    }

    try {
      // Simulasi fetching data varian produk
      return ProductVariant.fromCategory(category);
    } catch (e) {
      throw Exception('Gagal memuat varian produk: $e');
    }
  }

  void showCartDialog(BuildContext context, Map<String, dynamic> productMap) {
    final product = Product.fromMap(productMap);
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<ProductVariant?>(
          future: _fetchProductVariant(product.category),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(
                  'Gagal memuat varian untuk produk ini: ${snapshot.error}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            }
            final productVariant = snapshot.data;

            if (productVariant == null) {
              return AlertDialog(
                title: const Text('Tidak Tersedia'),
                content:
                    const Text('Varian untuk kategori ini tidak tersedia.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            }
            final variantKeys = productVariant.variants.keys.toList();
            final selectedOptions = <String, String?>{};

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Add to Cart - ${product.name}'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: variantKeys.map((variantKey) {
                        final options =
                            productVariant.variants[variantKey] ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variantKey.toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: selectedOptions[variantKey],
                              hint: Text('Pilih $variantKey'),
                              items: options
                                  .map<DropdownMenuItem<String>>((option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedOptions[variantKey] = value;
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Batal',
                          style: GoogleFonts.lato(
                              color: Color.fromRGBO(41, 68, 135, 1))),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedOptions.length == variantKeys.length &&
                            !selectedOptions.containsValue(null)) {
                          try {
                            await addtocarts(
                              context,
                              product,
                              selectedOptions.values.toList(),
                              1, // Default quantity
                            );
                            Navigator.of(context).pop();
                            _showSnackbar(
                                'Produk berhasil ditambahkan ke keranjang!');
                          } catch (e) {
                            print('Error adding product to cart: $e');
                            _showSnackbar(
                                'Terjadi kesalahan saat menambahkan ke keranjang.');
                          }
                        } else {
                          _showSnackbar(
                              'Mohon pilih semua varian sebelum menambahkan ke keranjang.');
                        }
                      },
                      child: const Text('Tambahkan ke Keranjang'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "Favorite",
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFavorites(), // Fetch favorites when building
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Failed to fetch favorites: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorite items yet.'));
          }

          favoriteItems =
              snapshot.data!; // Assign fetched data to favoriteItems

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.6,
            ),
            itemCount: favoriteItems.length,
            itemBuilder: (context, index) {
              final product = favoriteItems[index]['product'];
              if (product != null) {
                return ProductCard(
                  product: product,
                  showCartDialog: () => showCartDialog(context, product),
                  onRemoveFavorite: () => _removeFavorite(product['id']),
                );
              } else {
                return const Center(child: Text('Product not found'));
              }
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFavorites() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null || session.user == null) {
      throw Exception('Please log in to view favorites.');
    }

    try {
      final response = await Supabase.instance.client
          .from('wishlist')
          .select('*, product(*)')
          .eq('user_id', session.user.id);

      // Ensure response is not null and contains data
      return response != null ? List<Map<String, dynamic>>.from(response) : [];
    } catch (e) {
      throw Exception('Failed to fetch favorites: $e');
    }
  }

  Future<void> _removeFavorite(int productId) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.user == null) return;

    try {
      await Supabase.instance.client
          .from('wishlist')
          .delete()
          .eq('user_id', session.user.id)
          .eq('product_id', productId); // productId is now int

      // Remove the item from the local list
      setState(() {
        favoriteItems.removeWhere((item) => item['product']['id'] == productId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product removed from favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing favorite: $e')),
      );
    }
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onRemoveFavorite;
  final VoidCallback showCartDialog;

  const ProductCard({
    super.key,
    required this.product,
    required this.onRemoveFavorite,
    required this.showCartDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailProduct(productId: product['id']),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  product['imageurl'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image,
                          size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product['name'] ?? 'Unnamed Product',
              style:
                  GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              product['description'] ?? 'No Description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              CurrencyFormat.convertToIdr(product['price'] ?? 0, 2),
              style: GoogleFonts.lato(fontSize: 14, color: Colors.green),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onRemoveFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                onPressed: showCartDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrencyFormat {
  static String convertToIdr(num amount, int decimalDigit) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp. ',
      decimalDigits: decimalDigit,
    ).format(amount);
  }
}
