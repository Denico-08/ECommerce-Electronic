import 'package:google_fonts/google_fonts.dart';
import 'package:KlikGadget/main.dart';
import 'package:KlikGadget/screens/user/Detail_product.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:KlikGadget/screens/user/Favorite.dart';
import 'package:KlikGadget/screens/user/History.dart';
import 'package:KlikGadget/screens/user/Search.dart';
import 'package:KlikGadget/screens/user/Profile/user_profile.dart';
import 'package:KlikGadget/screens/user/cart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String userEmail;

  const HomePage({super.key, required this.username, required this.userEmail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Stream<List<Map<String, dynamic>>> _productsStream;
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> favoriteItems = [];
  List<Map<String, dynamic>> cartItems = [];
  int _cartItemCount = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _productsStream = supabase.from('product').stream(primaryKey: ['id']);
    _loadUserWishlist();
  }

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
      int productId, String color, String size) async {
    try {
      final response = await supabase
          .from('product_vars')
          .select('id')
          .eq('product_id', productId)
          .eq('color', color)
          .eq('size', size)
          .maybeSingle();

      if (response != null) {
        return response['id'];
      } else {
        final insertResponse = await supabase
            .from('product_vars')
            .insert({
              'product_id': productId,
              'color': color,
              'size': size,
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

  Future<void> _checkAndAddToCart(
      String color, String size, Map<String, dynamic> product) async {
    try {
      final productVarsId = await insertProductVar(product['id'], color, size);
      if (productVarsId == null) {
        _showSnackbar('Error: Failed to create product variant');
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        _showSnackbar('Please log in to add to cart');
        return;
      }

      final userId = session.user.id;

      final existingCartItem = await supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('product_vars_id', productVarsId)
          .maybeSingle();

      if (existingCartItem != null) {
        final newQuantity = existingCartItem['quantity'] + 1;
        await supabase
            .from('cart_items')
            .update({'quantity': newQuantity}).eq('id', existingCartItem['id']);
      } else {
        await supabase.from('cart_items').insert({
          'product_vars_id': productVarsId,
          'quantity': 1,
          'user_id': userId,
        });
      }

      _showSnackbar('Item added to cart');
    } catch (e) {
      print('Error adding item to cart: $e');
      _showSnackbar('Failed to add item to cart');
    }
  }

  Future<void> addToFavorites(Map<String, dynamic> product) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        final userId = session.user.id;

        final response = await supabase.from('wishlist').insert({
          'user_id': userId,
          'product_id': product['id'],
        });

        if (response == null) {
          setState(() {
            favoriteItems.add(product); // Add product to the favorites list
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product['name']} added to favorites'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding to wishlist: $response'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User is not logged in. Please log in first.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Exception occurred while adding to favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while adding to favorites.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeFromFavorites(Map<String, dynamic> product) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        final userId = session.user.id;

        // Remove the product from the user's wishlist
        final response = await supabase
            .from('wishlist')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', product['id']);

        if (response == null) {
          setState(() {
            favoriteItems.removeWhere((item) =>
                item['id'] == product['id']); // Remove product from the list
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product['name']} removed from favorites'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing from wishlist: $response'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User is not logged in. Please log in first.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Exception occurred while removing from favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while removing from favorites.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserWishlist() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('wishlist')
          .select('product_id')
          .eq('user_id', userId);

      setState(() {
        favoriteItems = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Exception occurred: $e');
    }
  }

  Future<void> addToCart(Map<String, dynamic> product) async {
    final productVarsId = await getProductVarsId(product['id'] as int);
    if (productVarsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add to cart: product vars ID is null'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    final userid = session.user.id;

    final existingCartItem = await supabase
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', userid)
        .eq('product_var_id', productVarsId)
        .maybeSingle();

    if (existingCartItem != null) {
      final newQuantity = existingCartItem['quantity'] + 1;
      await supabase
          .from('cart_items')
          .update({'quantity': newQuantity}).eq('id', existingCartItem['id']);
    } else {
      await supabase.from('cart_items').insert({
        'product_vars_id': productVarsId,
        'quantity': 1,
        'user_id': userid,
      });
    }

    final cartCountResponse =
        await supabase.from('cart_items').select('id').eq('user_id', userid);

    setState(() {
      _cartItemCount = cartCountResponse.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled,
                color: _selectedIndex == 0
                    ? Color.fromRGBO(41, 68, 135, 1)
                    : Color.fromARGB(255, 187, 213, 250)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite,
                color: _selectedIndex == 1
                    ? Color.fromRGBO(41, 68, 135, 1)
                    : const Color.fromARGB(255, 187, 213, 250)),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications,
                color: _selectedIndex == 2
                    ? Color.fromRGBO(41, 68, 135, 1)
                    : const Color.fromARGB(255, 187, 213, 250)),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: _selectedIndex == 3
                    ? const Color.fromARGB(255, 135, 108, 41)
                    : const Color.fromARGB(255, 187, 213, 250)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  List<Widget> _pages() {
    return <Widget>[
      HomeScreen(
        insertProductVar: insertProductVar,
        checkcart: _checkAndAddToCart,
        username: widget.username,
        addToCart: addToCart,
        addToFavorites: addToFavorites,
        removeFromFavorites: removeFromFavorites,
        cartItems: cartItems,
        favoriteItems: favoriteItems,
      ),
      FavoritePage(),
      const History(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
  List<Map<String, dynamic>> favoriteItems = [];
  List<Map<String, dynamic>> cartItems = [];
  bool _isCarouselVisible = true;
  String? _shippingAddress;
  int _cartItemCount = 0;
  int _current = 0;

  final List<String> promoImages = [
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/5.png',
  ];

  @override
  void initState() {
    super.initState();
    _productsStream = supabase.from('product').stream(primaryKey: ['id']);
    _scrollController.addListener(_handleScroll);

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final userId = session.user.id;
      _loadShippingAddress(userId);
    } else {
      setState(() {
        _shippingAddress = 'No user logged in';
      });
    }
  }

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
      int productId, String color, String size) async {
    try {
      final response = await supabase
          .from('product_vars')
          .select('id')
          .eq('product_id', productId)
          .eq('color', color)
          .eq('size', size)
          .maybeSingle();

      if (response != null) {
        return response['id'];
      } else {
        final insertResponse = await supabase
            .from('product_vars')
            .insert({
              'product_id': productId,
              'color': color,
              'size': size,
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

  Future<void> _loadShippingAddress(String userId) async {
    try {
      final response = await supabase
          .from('address')
          .select('alamat')
          .eq('user_id', userId)
          .order('id',
              ascending: true) // Get the first address by ordering by ID
          .limit(1) // Limit to one address
          .maybeSingle(); // Avoid throwing errors when no address found

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

  Future<void> addToCart(Map<String, dynamic> product) async {
    final productVarsId = await getProductVarsId(product['id'] as int);
    if (productVarsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add to cart: product vars ID is null'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    final userid = session.user.id;

    final existingCartItem = await supabase
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', userid)
        .eq('product_var_id', productVarsId)
        .maybeSingle();

    if (existingCartItem != null) {
      final newQuantity = existingCartItem['quantity'] + 1;
      await supabase
          .from('cart_items')
          .update({'quantity': newQuantity}).eq('id', existingCartItem['id']);
    } else {
      await supabase.from('cart_items').insert({
        'product_vars_id': productVarsId,
        'quantity': 1,
        'user_id': userid,
      });
    }

    final cartCountResponse =
        await supabase.from('cart_items').select('id').eq('user_id', userid);

    setState(() {
      _cartItemCount = cartCountResponse.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleScroll() {
    if (_scrollController.position.pixels > 150) {
      setState(() {
        _isCarouselVisible =
            false; // Hide carousel when scrolling past 150 pixels
      });
    } else {
      setState(() {
        _isCarouselVisible = true; // Show carousel when scrolling back up
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
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
          icon: Icon(Icons.search,
              size: MediaQuery.of(context).size.width < 600 ? 24 : 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchScreen()),
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
                SizedBox(width: 2),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
          if (_cartItemCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  '$_cartItemCount',
                  style: GoogleFonts.lato(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              children: [
                // Carousel Section
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isCarouselVisible
                      ? MediaQuery.of(context).size.height * 0.3
                      : 0,
                  child: Column(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: MediaQuery.of(context).size.height * 0.25,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _current = index;
                            });
                          },
                        ),
                        items: promoImages.map((imageUrl) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: double.infinity,
                                child: Image.asset(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: promoImages.asMap().entries.map((entry) {
                          return GestureDetector(
                            onTap: () => setState(() => _current = entry.key),
                            child: Container(
                              width: 6.0,
                              height: 6.0,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.white
                                        : Colors.blue)
                                    .withOpacity(
                                        _current == entry.key ? 0.9 : 0.4),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Product Grid Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0)
                      .copyWith(bottom: 18.0),
                  child: ListView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable scrolling in the ListView
                    shrinkWrap: true,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isFavorite = widget.favoriteItems
                          .any((item) => item['product_id'] == product['id']);
                      return SelectCard(
                        insertproductvar: widget.insertProductVar,
                        checkcart: widget.checkcart,
                        product: product,
                        addToCart: widget.addToCart,
                        addToFavorites: widget.addToFavorites,
                        removeFromFavorites: widget.removeFromFavorites,
                        isFavorite: isFavorite,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        final userId = session.user.id;

        // Refresh shipping address
        await _loadShippingAddress(userId);

        // Update cart item count
        final cartCountResponse = await supabase
            .from('cart_items')
            .select('id')
            .eq('user_id', userId);

        setState(() {
          _cartItemCount = cartCountResponse.length;
        });
      } else {
        setState(() {
          _shippingAddress = 'No user logged in';
          _cartItemCount = 0; // Reset cart item count if no user is logged in
        });
      }

      // Since _productsStream is already streaming changes, you may not need to do anything here,
      // but you can add any additional logic if required.
    } catch (e) {
      print('Error refreshing data: $e');
      _showSnackbar('Failed to refresh data.');
    }
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
  String? noodletype;
  String? cutlery;
  bool _isFavorite = false;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAverageRatingAndCount();
  }

  Future<Map<String, dynamic>> getAverageRatingAndCount(int productId) async {
    try {
      final response = await supabase
          .from('reviews')
          .select('rating')
          .eq('product_id', productId);

      if (response.isEmpty)
        return {'averageRating': 0.0, 'count': 0}; // No reviews

      num totalRating = 0.0;
      for (var review in response) {
        totalRating += review['rating'] as num;
      }

      num averageRating = totalRating / response.length; // Average rating
      return {
        'averageRating': averageRating,
        'count': response.length, // Count of reviews
      };
    } catch (e) {
      print('Error fetching average rating: $e');
      return {'averageRating': 0.0, 'count': 0}; // Return 0 in case of error
    }
  }

  Future<void> _fetchAverageRatingAndCount() async {
    final result = await getAverageRatingAndCount(widget.product['id']);
    setState(() {
      _averageRating = result['averageRating'];
      _reviewCount = result['count'];
    });
  }

  Future<void> refreshData() async {
    await _fetchAverageRatingAndCount();
  }

  void _showCartDialog() {
    String? selectedNoodleType = noodletype; // Local variable to hold the state
    String? selectedCutlery = cutlery; // Local variable to hold the state

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                "Select Options",
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    hint: Text("Type of Noodles"),
                    value: selectedNoodleType,
                    items: <String>['Thick', 'Thin']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedNoodleType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    hint: Text("Cutlery"),
                    value: selectedCutlery,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCutlery = newValue;
                      });
                    },
                    items: <String>['Spoon & Fork', 'Chopstick']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.lato(color: Colors.redAccent),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  child: Text(
                    "Add to Cart",
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                  onPressed: () async {
                    if (selectedNoodleType != null && selectedCutlery != null) {
                      await widget.insertproductvar(widget.product['id'],
                          selectedCutlery!, selectedNoodleType!);
                      await widget.checkcart(selectedCutlery!,
                          selectedNoodleType!, widget.product);
                      Navigator.of(context).pop();
                    } else {
                      _showSnackbar('Please select Type of Noodle and Cutlery');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailProduct(productId: widget.product['id']),
          ),
        ).then((_) {
          refreshData(); // Refresh when returning from detail page
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.3),
        margin: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.width < 600 ? 8 : 16,
          horizontal: MediaQuery.of(context).size.width < 600 ? 10 : 20,
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
                    aspectRatio:
                        MediaQuery.of(context).size.width < 600 ? 1.1 : 1.5,
                    child: Image.network(
                      widget.product['imageurl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.25,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
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
                      widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.isFavorite ? Colors.red : Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 6,
                  child: ElevatedButton(
                    onPressed: _showCartDialog,
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
              ],
            ),
            Padding(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['name'],
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          MediaQuery.of(context).size.width < 600 ? 16 : 20,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormat.convertToIdr(widget.product['price'], 2),
                    style: GoogleFonts.lato(
                      fontSize:
                          MediaQuery.of(context).size.width < 600 ? 14 : 18,
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
                        style: GoogleFonts.lato(fontSize: 16),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "($_reviewCount reviews)",
                        style: GoogleFonts.lato(color: Colors.grey),
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class CurrencyFormat {
  static String convertToIdr(num amount, int decimalDigit) {
    NumberFormat currencyFormatter = NumberFormat.currency(
        locale: 'id', symbol: 'Rp', decimalDigits: decimalDigit);
    return currencyFormatter.format(amount);
  }
}
