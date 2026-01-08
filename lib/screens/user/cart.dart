import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/screens/user/Checkout.dart';
import '../../Model/Varian.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> products = [];
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final productsData = await _fetchProducts();
      setState(() {
        products = productsData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('User is not authenticated.');
    }
    final userid = session.user.id;
    final cartItems = await _supabaseClient
        .from('cart_items')
        .select(
            'id, user_id, quantity, product_vars_id, product_vars!inner(product_id, category1, category2, category3, category4, category5, product!inner(name, price, category, imageurl))')
        .eq('user_id', userid);

    if (cartItems.isEmpty) {
      throw Exception('No cart items found for this user.');
    }

    final Map<int, Map<String, dynamic>> aggregatedProducts = {};

    for (var item in cartItems) {
      final productVarId = item['product_vars_id'] ?? 0;

      if (aggregatedProducts.containsKey(productVarId)) {
        aggregatedProducts[productVarId]!['quantity'] += item['quantity'] ?? 1;
      } else {
        aggregatedProducts[productVarId] = {
          'id': item['id'] as int? ?? 0,
          'quantity': item['quantity'] ?? 1,
          'product_vars_id': productVarId,
          'category1': item['product_vars']['category1'] ?? '',
          'category2': item['product_vars']['category2'] ?? '',
          'category3': item['product_vars']['category3'] ?? '',
          'category4': item['product_vars']['category4'] ?? '',
          'category5': item['product_vars']['category5'] ?? '',
          'name': item['product_vars']['product']['name'] ?? 'Unknown',
          'price': item['product_vars']['product']['price'] ?? 0.0,
          'imageurl': item['product_vars']['product']['imageurl'] ?? '',
          'category': item['product_vars']['product']['category'] ?? '',
        };
      }
    }
    return aggregatedProducts.values.toList();
  }

  Future<void> _incrementQuantity(int index) async {
    final currentQuantity = products[index]['quantity'] as int? ?? 0;
    final updatedQuantity = currentQuantity + 1;
    await _updateCartItemQuantity(index, updatedQuantity);
  }

  Future<void> _decrementQuantity(int index) async {
    final currentQuantity = products[index]['quantity'] as int? ?? 1;

    if (currentQuantity > 1) {
      final updatedQuantity = currentQuantity - 1;
      await _updateCartItemQuantity(index, updatedQuantity);
    } else {
      await _removeCartItem(index);
    }
  }

  Future<void> _updateCartItemQuantity(int index, int quantity) async {
    try {
      print(
          'Updating cart item with ID: ${products[index]['id']} and quantity: $quantity');
      await _supabaseClient.from('cart_items').update(
          {'quantity': quantity}).eq('id', products[index]['id'] as int? ?? 0);
      setState(() {
        products[index]['quantity'] = quantity;
      });
    } catch (e) {
      print('Caught error: $e');
      throw Exception('Error updating cart');
    }
  }

  Future<void> _removeCartItem(int index) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final userid = session.user.id;
      final response = await _supabaseClient
          .from('cart_items')
          .delete()
          .eq('product_vars_id', products[index]['product_vars_id'])
          .eq('user_id', userid);

      if (response == null) {
        setState(() {
          products.removeAt(index);
        });
      } else {
        throw Exception('Error deleting from cart');
      }
    }
  }

  num _calculateTotalPrice() {
    return products.fold(0.0, (sum, item) {
      final price = (item['price'] as num?) ?? 0.0;
      final quantity = (item['quantity'] as int?) ?? 0;
      return sum + price * quantity;
    });
  }

  int _calculateTotalQuantity() {
    return products.fold(0, (sum, item) {
      final quantity = (item['quantity'] as int?) ?? 0;
      return sum + quantity;
    });
  }

  List<String> _getVariantDescriptions(
      String category, Map<String, dynamic> item) {
    try {
      // Mendapatkan objek ProductVariant berdasarkan kategori
      final productVariant = ProductVariant.fromCategory(category);

      // Membuat daftar nama kategori yang relevan (category1-category5)
      final List<String> categoryKeys = [
        'category1',
        'category2',
        'category3',
        'category4',
        'category5',
      ];

      // Iterasi untuk memetakan nama varian dan nilai
      final descriptions = categoryKeys
          .map((key) {
            if (item[key] != null && item[key].isNotEmpty) {
              // Mendapatkan nama atribut (key) dari data varian
              final variantName = productVariant.variants.keys.firstWhere(
                (k) => productVariant.variants[k]!.contains(item[key]),
                orElse: () => '',
              );

              // Mengembalikan deskripsi
              if (variantName.isNotEmpty) {
                return '${variantName}: ${item[key]}';
              }
            }
            return null; // Tidak ditemukan
          })
          .where((element) => element != null)
          .toList();

      return descriptions.cast<String>();
    } catch (e) {
      // Jika kategori tidak ditemukan
      return ['Error: Category not supported'];
    }
  }

  Widget _buildProductCard(Map<String, dynamic> item, double screenWidth) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item['imageurl'],
                width: screenWidth * 0.25,
                height: screenWidth * 0.25,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Spesifikasi:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._getVariantDescriptions(item['category'] ?? '', item)
                      .map((description) {
                    return Text(
                      '- $description',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _incrementQuantity(products.indexOf(item)),
                ),
                Text(
                  item['quantity'].toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _decrementQuantity(products.indexOf(item)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart', style: GoogleFonts.lato()),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final item = products[index];
                      return _buildProductCard(item, screenWidth);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormat.convertToIdr(
                                _calculateTotalPrice(), 2),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Checkout()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(41, 68, 135, 1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Proceed to Checkout',
                            style: GoogleFonts.lato(
                                fontSize: 17, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class CurrencyFormat {
  static String convertToIdr(num number, int decimal) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: decimal,
    );
    return formatCurrency.format(number);
  }
}
