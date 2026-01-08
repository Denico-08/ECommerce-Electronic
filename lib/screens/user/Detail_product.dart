import 'package:KlikGadget/screens/user/Review.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/Model/Varian.dart';
import 'package:KlikGadget/main.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final String imageUrls;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.category,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String,
      imageUrls: map['imageurl'] as String,
      category: map['category'] as String, // Retrieve category from the map
    );
  }
}

// Format mata uang IDR
String convertToIdr(num number, int decimalDigit) {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: decimalDigit,
  );
  return currencyFormatter.format(number);
}

Future<void> _updateProductVars(
    int productId, List<String?> selectedVariants) async {
  try {
    final updateData = {
      'category1': selectedVariants.isNotEmpty ? selectedVariants[0] : null,
      'category2': selectedVariants.length > 1 ? selectedVariants[1] : null,
      'category3': selectedVariants.length > 2 ? selectedVariants[2] : null,
      'category4': selectedVariants.length > 3 ? selectedVariants[3] : null,
      'category5': selectedVariants.length > 4 ? selectedVariants[4] : null,
    };

    final response = await supabase.from('product_vars').update(updateData).eq(
        'product_id',
        productId); // Gunakan `execute()` untuk mendapatkan hasil respons lengkap

    if (response != null) {
      print('Error updating product vars: ${response.error?.message}');
    } else {
      print('Product vars updated successfully');
    }
  } catch (e) {
    print('Exception occurred while updating product vars: $e');
  }
}

Future<int?> getProductVarsId(
    int productId, Map<String, String?> selectedVariants) async {
  try {
    final response = await supabase
        .from('product_vars')
        .select('id')
        .eq('product_id', productId)
        .eq('category1', selectedVariants)
        .eq('category2', selectedVariants)
        .eq('category3', selectedVariants)
        .eq('category4', selectedVariants)
        .eq('category5', selectedVariants)
        .maybeSingle(); // Use maybeSingle() to avoid exceptions for zero rows

    if (response == null) {
      print('No matching product variant found for the selected categories.');
      return null;
    }
    print(response);

    return response['id'] as int?;
  } catch (e) {
    print('Exception occurred while fetching product vars ID: $e');
    return null;
  }
}

Future<void> addToCart(BuildContext context, Product product,
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
          'category1': selectedVariants.isNotEmpty ? selectedVariants[0] : null,
          'category2': selectedVariants.length > 1 ? selectedVariants[1] : null,
          'category3': selectedVariants.length > 2 ? selectedVariants[2] : null,
          'category4': selectedVariants.length > 3 ? selectedVariants[3] : null,
          'category5': selectedVariants.length > 4 ? selectedVariants[4] : null,
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

class DetailProduct extends StatefulWidget {
  final int productId;
  const DetailProduct({super.key, required this.productId});

  @override
  _DetailProductState createState() => _DetailProductState();
}

class _DetailProductState extends State<DetailProduct> {
  late Future<Product> _productFuture;
  int _quantity = 1;
  Map<String, String?> selectedVariants =
      {}; // Holds the selected variant options dynamically
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProductDetails();
    _loadReviews();
  }

  Future<Product> _fetchProductDetails() async {
    final response = await supabase
        .from('product')
        .select()
        .eq('id', widget.productId)
        .single();

    return Product.fromMap(response);
  }

  Future<void> _loadReviews() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('reviews')
          .select('*, user:users(username)')
          .eq('product_id', widget.productId);

      print(response);

      final data = response as List<dynamic>;
      setState(() {
        reviews = data
            .map((review) => {
                  'username': review['user']?['username'] ?? 'Anonymous',
                  'rating': review['rating'],
                  'comment': review['comment'],
                  'date': review['date'],
                })
            .toList();
        isLoading = false;
      });
    } catch (error) {
      print("Error loading reviews: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_fetchProductDetails(), _loadReviews()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _refresh();
            },
          ),
        ],
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final product = snapshot.data!;

          // Fetch variants dynamically based on the product's category
          final productVariant = ProductVariant.fromCategory(product.category);
          final variants = productVariant.variants;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // Product Image
                Container(
                  height: 400,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(product.imageUrls),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ..._buildVariantWidgets(variants.cast<String, List<String>>()),

                SizedBox(height: 5),

                Text(
                  product.name,
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      convertToIdr(product.price, 2),
                      style: GoogleFonts.lato(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (_quantity > 1) {
                                _quantity--;
                              }
                            });
                          },
                        ),
                        Text(
                          "$_quantity",
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  product.description,
                  style: GoogleFonts.lato(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await addToCart(context, product,
                          selectedVariants.values.toList(), _quantity);
                    },
                    child: Text(
                      "Add to Cart",
                      style:
                          GoogleFonts.lato(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(41, 68, 135, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmitReviewPage(
                          productId: widget.productId,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Write a Review",
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 62, 123, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section for Displaying Reviews
                Text(
                  "Customer Reviews",
                  style: GoogleFonts.lato(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Review display section
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : reviews.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review['username'] ?? 'Anonymous',
                                        style: GoogleFonts.lato(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      RatingBarIndicator(
                                        rating:
                                            review['rating']?.toDouble() ?? 0.0,
                                        itemBuilder: (context, index) =>
                                            const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        itemCount: 5,
                                        itemSize: 20.0,
                                        direction: Axis.horizontal,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        review['comment'] ?? "",
                                        style: GoogleFonts.lato(fontSize: 16),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Posted on: ${review['date']}",
                                        style: GoogleFonts.lato(
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(child: Text("No reviews yet")),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build variant selection widgets based on product variants
  List<Widget> _buildVariantWidgets(Map<String, List<String>> variants) {
    List<Widget> variantWidgets = [];

    variants.forEach((category, options) {
      variantWidgets.add(_buildVariantOption(category, options));
    });

    return variantWidgets;
  }

  Widget _buildVariantOption(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          children: options
              .map((option) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedVariants[title] =
                            option; // Update the selected variant
                      });
                      _updateProductVars(
                          widget.productId,
                          selectedVariants.values
                              .toList()); // Update product variants in the database
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Chip(
                        label: Text(
                          option,
                          style: GoogleFonts.lato(color: Colors.black),
                        ),
                        backgroundColor: selectedVariants[title] == option
                            ? Colors.blue // Change color if selected
                            : const Color.fromARGB(
                                255, 255, 255, 255), // Default color
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(
          height: 10,
        )
      ],
    );
  }
}
