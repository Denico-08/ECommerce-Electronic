// ignore_for_file: unused_field

import 'package:KlikGadget/screens/user/Profile/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/screens/user/home_screen.dart';
import 'package:KlikGadget/screens/user/Favorite.dart';
import 'package:KlikGadget/screens/user/History.dart';

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

        await supabase.from('wishlist').insert({
          'user_id': userId,
          'product_id': product['id'],
        });

        setState(() {
          favoriteItems.add(product);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['name']} added to favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
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

        await supabase
            .from('wishlist')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', product['id']);

        setState(() {
          favoriteItems.removeWhere((item) => item['id'] == product['id']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['name']} removed from favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
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
        currentIndex: _selectedIndex,
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
                    : Color.fromARGB(255, 187, 213, 250)),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications,
                color: _selectedIndex == 2
                    ? Color.fromRGBO(41, 68, 135, 1)
                    : Color.fromARGB(255, 187, 213, 250)),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: _selectedIndex == 3
                    ? Color.fromRGBO(41, 68, 135, 1)
                    : Color.fromARGB(255, 187, 213, 250)),
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
        addToCart: (product) => addToFavorites(product),
        addToFavorites: addToFavorites,
        removeFromFavorites: removeFromFavorites,
        cartItems: cartItems,
        favoriteItems: favoriteItems,
      ),
      const FavoritePage(),
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
