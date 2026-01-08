import 'package:google_fonts/google_fonts.dart';
import 'package:KlikGadget/screens/user/Detail_product.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Add this package for number formatting

class SearchScreen extends StatefulWidget {
  final String selectedFilter;

  const SearchScreen({super.key, this.selectedFilter = ''});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late String filter;
  String searchQuery = '';
  late final SupabaseClient supabase;
  List<Map<String, dynamic>> allProducts = [];
  bool isLoading = true;
  List<Map<String, dynamic>> favoriteItems = [];
  List<Map<String, dynamic>> cartItems = [];
  int _cartItemCount = 0;
  String? selectedtype;
  String? selectedcutlery;

  @override
  void initState() {
    super.initState();
    filter = widget.selectedFilter;
    supabase = Supabase.instance.client;
    _fetchProducts();
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

  void _showCartDialog(Map<String, dynamic> product) {
    String? selectednoodletype =
        selectedtype; // Local variable to hold the state
    String? cutlery = selectedcutlery; // Local variable to hold the state

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
                    hint: Text("Select Noodle Type"),
                    value: selectednoodletype,
                    items: <String>['Thick', 'Thin']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectednoodletype = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    hint: Text("Select Size"),
                    value: cutlery,
                    onChanged: (newValue) {
                      setState(() {
                        cutlery = newValue;
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
                    backgroundColor:
                        const Color.fromARGB(255, 0, 0, 0), // Button color
                  ),
                  child: Text(
                    "Add to Cart",
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                  onPressed: () async {
                    if (selectednoodletype != null && cutlery != null) {
                      await insertProductVar(
                          product['id'], cutlery!, selectednoodletype!);
                      await _checkAndAddToCart(
                          cutlery!, selectednoodletype!, product);
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await supabase.from('product').select('*');
      final data = response as List<dynamic>;
      setState(() {
        allProducts = data.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Exception fetching products: $e');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      filter = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = allProducts.where((product) {
      final matchesFilter = filter.isEmpty || product['category'] == filter;
      final matchesSearch = searchQuery.isEmpty ||
          (product['name'] as String)
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  // Top Categories using GestureDetector
                  SizedBox(
                    height: 110,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CategoryButton(
                          imagePath: 'assets/images/ic_tv.png',
                          label: "TV & Audio",
                          selected: filter == "Soba",
                          onTap: () => _onCategorySelected("Soba"),
                        ),
                        CategoryButton(
                          imagePath: 'assets/images/ic_hp.png',
                          label: "Tablet & HP",
                          selected: filter == "Udon",
                          onTap: () => _onCategorySelected("Udon"),
                        ),
                        CategoryButton(
                          imagePath: 'assets/images/ic_laptop.png',
                          label: "Laptop",
                          selected: filter == "Ramen",
                          onTap: () => _onCategorySelected("Ramen"),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return SelectCard(
                          product: product,
                          showCartDialog: () => _showCartDialog(product),
                          toggleFavorite: () => addToFavorites(product),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.imagePath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: selected
                ? Colors.blue[100] // Light blue for selected state
                : Colors.grey[200], // Light grey for unselected state
            radius: 30,
            child: Image.asset(
              imagePath,
              height: 24,
              width: 24,
              color: null, // Keep the icon color as original
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.black
                  : Colors.grey[600], // Dark grey for unselected
            ),
          ),
        ],
      ),
    );
  }
}

class SelectCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback toggleFavorite;
  final VoidCallback showCartDialog;

  const SelectCard(
      {super.key,
      required this.product,
      required this.toggleFavorite,
      required this.showCartDialog});

  String formatPrice(int price) {
    final formatter = NumberFormat("#,##0", "en_US");
    return formatter
        .format(price)
        .replaceAll(',', '.'); // Replace commas with dots
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailProduct(productId: product['id']),
          ),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailProduct(productId: product['id']),
                  ),
                );
              },
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: product['imageurl'] != null
                      ? Image.network(
                          product['imageurl'],
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 150),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'No Title',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['price'] != null
                        ? 'Rp. ${formatPrice(product['price'])}'
                        : 'No Price',
                    style: GoogleFonts.lato(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.black),
                  onPressed: showCartDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.black),
                  onPressed: toggleFavorite,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
