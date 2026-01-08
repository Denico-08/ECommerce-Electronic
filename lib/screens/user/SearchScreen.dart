import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) addToCart;
  final String selectedFilter;

  const SearchScreen(
      {super.key, required this.addToCart, this.selectedFilter = ''});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late String filter;
  String searchQuery = '';
  late final SupabaseClient supabase;
  List<Map<String, dynamic>> allProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    filter = widget.selectedFilter;
    supabase = Supabase.instance.client;
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await supabase
          .from('product') // Replace with your actual table name
          .select('*');

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

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

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
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: SizedBox(
          height: 45,
          width: screenSize.width * 0.7,
          child: SearchBarApp(onSearchChanged: _onSearchChanged),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final categories = allProducts
                      .map((product) => product['category'] as String)
                      .toSet()
                      .toList();
                  return AlertDialog(
                    title: const Text('Select Category'),
                    content: SingleChildScrollView(
                      child: Column(
                        children: categories.map((category) {
                          return ListTile(
                            title: Text(category),
                            onTap: () {
                              Navigator.of(context).pop();
                              setState(() {
                                filter = category;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                FilterButtons(onFilterSelected: (selectedFilter) {
                  setState(() {
                    filter = selectedFilter;
                  });
                }),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenSize.width > 600 ? 3 : 2,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 0.75, // Adjust as needed
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return SelectCard(
                        product: product,
                        addToCart: () => widget.addToCart(product),
                        toggleFavorite: () {
                          // Implement toggleFavorite if needed
                        },
                        favoriteItems: const [],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class SearchBarApp extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const SearchBarApp({super.key, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: SizedBox(
        child: TextField(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
            hintText: 'Search...',
            prefixIcon: const Icon(Icons.search, size: 18.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          style: GoogleFonts.lato(fontSize: 14),
          onChanged: onSearchChanged,
        ),
      ),
    );
  }
}

class FilterButtons extends StatelessWidget {
  final ValueChanged<String> onFilterSelected;

  const FilterButtons({super.key, required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    final filters = [
      'HP',
      'Laptop',
      'TV',
      'Tablet',
      'Radio',
    ];

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () => onFilterSelected(filter),
                child: Text(
                  filter,
                  style:
                      GoogleFonts.lato(color: Color.fromRGBO(41, 68, 135, 1)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SelectCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback addToCart;
  final VoidCallback toggleFavorite;

  const SelectCard({
    super.key,
    required this.product,
    required this.addToCart,
    required this.toggleFavorite,
    required List<Map<String, dynamic>> favoriteItems,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              // Navigate to product details or other action
            },
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: product['imageurl'] != null &&
                        product['imageurl'].isNotEmpty
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
                        fontSize: 12,
                      ),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(color: Colors.black),
                Text(
                  product['price'] != null
                      ? 'Rp ${product['price']}'
                      : 'No Price',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.start,
                ),
                const Divider(color: Colors.black),
                const SizedBox(height: 5),
                // Add your rating and reviews if available
              ],
            ),
          ),
          OverflowBar(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: addToCart,
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: toggleFavorite,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
