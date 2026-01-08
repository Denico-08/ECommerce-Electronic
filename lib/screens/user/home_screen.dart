import 'package:google_fonts/google_fonts.dart';
import 'package:KlikGadget/main.dart';
import 'package:KlikGadget/screens/user/Detail_product.dart';
import 'package:KlikGadget/screens/user/SearchScreen.dart';
import 'package:KlikGadget/screens/user/cart.dart';
import 'package:KlikGadget/Model/Varian.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Product {
  final int id;
  final String name;
  final String category; // New field for category

  Product({
    required this.id,
    required this.name,
    required this.category, // Add category to the constructor
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String, // Retrieve category from the map
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String username;
  final Function(String, String, Map<String, dynamic>) checkcart;
  final Function(int, String, String) insertProductVar;
  final Function(Map<String, dynamic>) addToCart;
  final Function(Map<String, dynamic>) addToFavorites;
  final Function(Map<String, dynamic>) removeFromFavorites;
  final List<Map<String, dynamic>> cartItems;
  final List<Map<String, dynamic>> favoriteItems;

  const HomeScreen({
    super.key,
    required this.username,
    required this.checkcart,
    required this.addToCart,
    required this.addToFavorites,
    required this.removeFromFavorites,
    required this.insertProductVar,
    required this.cartItems,
    required this.favoriteItems,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Map<String, dynamic>>> _productsStream;
  final SupabaseClient supabase = Supabase.instance.client;
  ScrollController _scrollController = ScrollController();
  String? _shippingAddress;
  int _cartItemCount = 0;

  final List<String> promoImages = [
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/5.png',
  ];

  @override
  void initState() {
    super.initState();
    _productsStream = supabase.from('product').stream(primaryKey: ['id']);
    _scrollController.addListener;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _loadShippingAddress(session.user.id);
    } else {
      setState(() {
        _shippingAddress = 'No user logged in';
      });
    }
  }

  Future<void> _loadShippingAddress(String userId) async {
    try {
      final response = await supabase
          .from('address')
          .select('alamat')
          .eq('user_id', userId)
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();

      setState(() {
        _shippingAddress = response?['alamat'] ?? 'No address available';
      });
    } catch (error) {
      print('Error loading address: $error');
      setState(() {
        _shippingAddress = 'No address available';
      });
    }
  }

  Future<void> _loadShippingAddressWrapper() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _loadShippingAddress(session.user.id);
    } else {
      setState(() {
        _shippingAddress = 'No user logged in';
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      SearchScreen(addToCart: widget.addToCart)),
            );
          },
        ),
        title: Column(
          children: [
            Text(
              'Deliver Now',
              style: GoogleFonts.lato(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    _shippingAddress ?? 'Loading address...',
                    style: GoogleFonts.lato(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => CartScreen()));
            },
          ),
          if (_cartItemCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text('$_cartItemCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _loadShippingAddressWrapper,
            child: ListView.builder(
              itemCount: products.length + 1, // +1 for the carousel
              itemBuilder: (context, index) {
                if (index == 0) {
                  // This will be the CarouselSlider
                  return CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      aspectRatio: 16 / 9,
                      viewportFraction: 1.0,
                    ),
                    items: promoImages.map((item) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.asset(item, fit: BoxFit.cover),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                }
                final product =
                    products[index - 1]; // Adjust the index for the carousel
                return SelectCard(
                  product: product,
                  checkcart: widget.checkcart,
                  addToCart: widget.addToCart,
                  addToFavorites: widget.addToFavorites,
                  removeFromFavorites: widget.removeFromFavorites,
                  insertproductvar: widget.insertProductVar,
                  isFavorite: widget.favoriteItems.contains(product),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SelectCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(String, String, Map<String, dynamic>) checkcart;
  final Function(Map<String, dynamic>) addToCart;
  final Function(Map<String, dynamic>) addToFavorites;
  final Function(Map<String, dynamic>) removeFromFavorites;
  final Function(int, String, String) insertproductvar;
  final bool isFavorite;

  const SelectCard({
    super.key,
    required this.product,
    required this.checkcart,
    required this.addToCart,
    required this.addToFavorites,
    required this.removeFromFavorites,
    required this.insertproductvar,
    required this.isFavorite,
  });

  @override
  State<SelectCard> createState() => _SelectCardState();
}

class _SelectCardState extends State<SelectCard> {
  double _averageRating = 0.0;
  int _reviewCount = 0;
  Map<String, String?> selectedVariants = {};
  bool _isFavorite = false;
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();
    _fetchAverageRatingAndCount();
  }

  Future<void> _fetchAverageRatingAndCount() async {
    final result = await _getAverageRatingAndCount(widget.product['id']);
    setState(() {
      _averageRating = result['averageRating'];
      _reviewCount = result['count'];
    });
  }

  Future<void> _addToCart(BuildContext context, Product product,
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

  Future<Map<String, dynamic>> _getAverageRatingAndCount(int productId) async {
    try {
      final response = await supabase
          .from('reviews')
          .select('rating')
          .eq('product_id', productId);
      if (response.isEmpty) return {'averageRating': 0.0, 'count': 0};

      final totalRating =
          response.fold(0.0, (sum, review) => sum + (review['rating'] as num));
      return {
        'averageRating': totalRating / response.length,
        'count': response.length
      };
    } catch (e) {
      print('Error fetching ratings: $e');
      return {'averageRating': 0.0, 'count': 0};
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Error'),
                ],
              ),
              content: Text(
                'Gagal memuat varian untuk produk ini: ${snapshot.error}',
                style: TextStyle(color: Colors.black87),
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
              title: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Tidak Tersedia'),
                ],
              ),
              content: const Text(
                'Varian untuk kategori ini tidak tersedia.',
                style: TextStyle(color: Colors.black87),
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Text(
                  'Add to Cart - ${product.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: variantKeys.map((variantKey) {
                      final options = productVariant.variants[variantKey] ?? [];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variantKey.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: selectedOptions[variantKey],
                                isExpanded: true,
                                hint: Text('Pilih $variantKey'),
                                underline: SizedBox.shrink(),
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
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      if (selectedOptions.length == variantKeys.length &&
                          !selectedOptions.containsValue(null)) {
                        try {
                          await _addToCart(
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
                    child: Text('Tambahkan ke Keranjang'),
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

  Future<void> refreshData() async {
    await _fetchAverageRatingAndCount();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailProduct(productId: widget.product['id']),
          ),
        ).then((_) {
          refreshData();
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.3),
        margin: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 8 : 16,
          horizontal: isSmallScreen ? 10 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: AspectRatio(
                    aspectRatio: isSmallScreen ? 1.1 : 1.5,
                    child: Image.network(
                      widget.product['imageurl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.25,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 6,
                  child: ElevatedButton(
                    onPressed: () => showCartDialog(context, widget.product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.black,
                    ),
                  ),
                ),
                Positioned(
                  left: 11,
                  bottom: 6,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                      if (_isFavorite) {
                        widget.addToFavorites(widget.product);
                      } else {
                        widget.removeFromFavorites(widget.product);
                      }
                      refreshData();
                    },
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 20,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormat.convertToIdr(widget.product['price'], 2),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: _averageRating,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 30.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "($_reviewCount reviews)",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
