import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/screens/user/Payment.dart';

class Checkout extends StatefulWidget {
  const Checkout({super.key});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> products = [];
  List<dynamic> addresses = [];
  String? selectedAddress;
  List<String> paymentMethods = [
    'Cash On Delivery',
    'Credit',
    'Virtual Account',
    'Pay Later'
  ];
  List<String> couriers = [
    'Express (1-3 days)',
    'Reguler (1-5 days)',
    'Same Day'
  ];
  String? selectedCourier;
  String? selectedPaymentMethod;
  num userBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _fetchAddresses();
    _fetchUserBalance();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      products = await _fetchProducts();
    } catch (e) {
      _showSnackbar('Error loading products: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserBalance() async {
    final session = _supabaseClient.auth.currentSession;
    if (session == null) return _showSnackbar('User is not authenticated.');

    final userId = session.user.id;
    final balanceResponse = await _supabaseClient
        .from('users')
        .select('saldo')
        .eq('id', userId)
        .single();

    if (balanceResponse != null) {
      setState(() {
        userBalance = balanceResponse['saldo'] ?? 0.0;
      });
    } else {
      _showSnackbar('Failed to fetch user balance.');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final session = _supabaseClient.auth.currentSession;
    if (session == null) throw Exception('User is not authenticated.');

    final userId = session.user.id;
    final cartItems = await _supabaseClient
        .from('cart_items')
        .select(
            'id, user_id, quantity, product_vars_id, product_vars!inner(product_id, product!inner(name, price, imageurl))')
        .eq('user_id', userId);

    if (cartItems == null || cartItems.isEmpty) {
      throw Exception('No cart items found.');
    }

    final Map<int, Map<String, dynamic>> aggregatedProducts = {};
    for (var item in cartItems) {
      final productVarId = item['product_vars_id'] ?? 0;
      if (aggregatedProducts.containsKey(productVarId)) {
        aggregatedProducts[productVarId]!['quantity'] += item['quantity'] ?? 1;
      } else {
        final productVarDetails = await _supabaseClient
            .from('product_vars')
            .select('category1, category2, category3, category4, category5')
            .eq('id', productVarId)
            .single();

        aggregatedProducts[productVarId] = {
          'id': item['id'] as int? ?? 0,
          'quantity': item['quantity'] ?? 1,
          'product_vars_id': productVarId,
          'product_id': item['product_vars']['product_id'] ?? 0,
          'name': item['product_vars']['product']['name'] ?? 'Unknown',
          'price': item['product_vars']['product']['price'] ?? 0.0,
          'imageurl': item['product_vars']['product']['imageurl'] ?? '',
          'category1': productVarDetails['category1'] ?? 'Unknown',
          'category2': productVarDetails['category2'] ?? 'Unknown',
          'category3': productVarDetails['category3'] ?? 'Unknown',
          'category4': productVarDetails['category4'] ?? 'Unknown',
          'category5': productVarDetails['category5'] ?? 'Unknown',
        };
      }
    }
    return aggregatedProducts.values.toList();
  }

  Future<void> _fetchAddresses() async {
    final session = _supabaseClient.auth.currentSession;
    if (session == null) return _showSnackbar('User is not authenticated.');

    final userId = session.user.id;
    final response = await _supabaseClient
        .from('address')
        .select('id, alamat')
        .eq('user_id', userId);

    if (response != null && response.isNotEmpty) {
      setState(() {
        addresses = response;
      });
    } else {
      _showSnackbar('No addresses found for the user.');
    }
  }

  Future<void> _processPayment() async {
    final session = _supabaseClient.auth.currentSession;
    if (session == null) return _showSnackbar('User is not authenticated.');

    if (selectedAddress == null ||
        selectedCourier == null ||
        selectedPaymentMethod == null) {
      return _showSnackbar(
          'Please complete the address, courier, and payment method.');
    }

    final userId = session.user.id;
    final totalAmount = _calculateTotalPrice().toInt();

    final addressResponse = await _supabaseClient
        .from('address')
        .select('id')
        .eq('alamat', selectedAddress as Object)
        .single();

    if (addressResponse.isEmpty) {
      return _showSnackbar('Failed to retrieve address.');
    }
    final addressId = addressResponse['id'];

    final balanceResponse = await _supabaseClient
        .from('users')
        .select('saldo')
        .eq('id', userId)
        .single();

    final userBalance = balanceResponse['saldo'] ?? 0.0;
    if (userBalance >= totalAmount) {
      final updatedBalance = (userBalance - totalAmount);
      final updateResponse = await _supabaseClient
          .from('users')
          .update({'saldo': updatedBalance}).eq('id', userId);
      if (updateResponse != null) {
        return _showSnackbar('Failed to update balance.');
      } else {
        final orderResponse = await _supabaseClient
            .from('orders')
            .insert({
              'user_id': userId,
              'shipping_address_id': addressId,
              'total_amount': totalAmount,
            })
            .select()
            .single();

        if (orderResponse == null) {
          return _showSnackbar('Failed to create order.');
        }

        final orderId = orderResponse['id'] as int;
        for (var product in products) {
          final productVarId = product['product_vars_id'];

          // Check if productVarId exists in product_vars
          final productVarExists = await _supabaseClient
              .from('product_vars')
              .select('id')
              .eq('id', productVarId)
              .single();

          if (productVarExists.isNotEmpty) {
            final orderItemResponse = await _supabaseClient
                .from('order_items')
                .insert({
                  'order_id': orderId,
                  'quantity': product['quantity'],
                  'product_vars_id': productVarId,
                })
                .select()
                .single();

            final orderItemId = orderItemResponse['id'];
            final productId = product['product_id'];

            final transactionResponse =
                await _supabaseClient.from('transaksi').insert({
              'order_items_id': orderItemId,
              'product_vars_id': productVarId,
              'product_id': productId,
              'user_id': userId
            });

            if (transactionResponse != null) {
              _showSnackbar('Failed to process transaction.');
            } else {
              _showSnackbar('Transaction successfully processed.');
            }
          }
        }

        // Clear cart items after successful payment
        await _clearCartItems(userId);

        _showSnackbar('Payment successful.');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Payment(
              userId: userId,
              address: selectedAddress!,
              paymentMethod: selectedPaymentMethod!,
              courier: selectedCourier!,
              totalAmount: totalAmount,
              totalQuantity: _calculateTotalQuantity(),
            ),
          ),
        );
      }
    } else {
      _showSnackbar('Insufficient balance.');
    }
  }

  Future<void> _clearCartItems(String userId) async {
    await _supabaseClient.from('cart_items').delete().eq('user_id', userId);
  }

  num _calculateTotalPrice() {
    return products.fold(0.0, (sum, item) {
      final price = item['price'] as int? ?? 0.0;
      final quantity = item['quantity'] as int? ?? 0;
      return sum + price * quantity;
    });
  }

  int _calculateTotalQuantity() {
    return products.fold(0, (sum, item) {
      return sum + (item['quantity'] as int? ?? 0);
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Check Out', style: GoogleFonts.lato()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: products
                            .map((product) =>
                                _buildProductCard(product, screenWidth))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceSummary(),
                  const SizedBox(height: 16.0),
                  _buildDropdowns(),
                  const SizedBox(
                    height: 16.0,
                    width: double.infinity,
                  ),
                  _buildProceedButton(context),
                ],
              ),
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, double screenWidth) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Product Image
            Image.network(
              product['imageurl'],
              width: screenWidth * 0.2, // Adjust image size dynamically
              height: screenWidth * 0.2,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 16.0),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8.0),
                  Text('Quantity: ${product['quantity']}'),
                  Text(
                      'Total Price: ${NumberFormat.currency(locale: 'id', symbol: 'Rp').format(product['price'] * product['quantity'])}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total:'),
            Text(
              NumberFormat.currency(locale: 'id', symbol: 'Rp')
                  .format(_calculateTotalPrice()),
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Balance:', style: GoogleFonts.lato()),
            Text(
              NumberFormat.currency(locale: 'id', symbol: 'Rp')
                  .format(userBalance),
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdowns() {
    return Column(
      children: [
        _buildDropdown(
          'Select Address',
          selectedAddress,
          addresses.map((address) => address['alamat'] as String).toList(),
          (value) {
            setState(() {
              selectedAddress = value;
            });
          },
        ),
        const SizedBox(height: 10),
        _buildDropdown(
          'Delivery Option',
          selectedCourier,
          couriers,
          (value) {
            setState(() {
              selectedCourier = value;
            });
          },
        ),
        const SizedBox(height: 10),
        _buildDropdown(
          'Select Payment Method',
          selectedPaymentMethod,
          paymentMethods,
          (value) {
            setState(() {
              selectedPaymentMethod = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(String hint, String? selectedValue, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint),
          value: selectedValue,
          onChanged: onChanged, // Handle dropdown value change
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.lato(color: Colors.black)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProceedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(41, 68, 135, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _processPayment,
        child: Text(
          'Submit Order',
          style: GoogleFonts.lato(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
