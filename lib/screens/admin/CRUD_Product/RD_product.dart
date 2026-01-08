import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/screens/admin/CRUD_Product/C_product.dart';
import 'package:KlikGadget/screens/admin/CRUD_Product/U_product.dart';
import 'package:intl/intl.dart';

class Admin_Barang extends StatefulWidget {
  const Admin_Barang({super.key});

  @override
  _Admin_BarangState createState() => _Admin_BarangState();
}

class _Admin_BarangState extends State<Admin_Barang> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> barang;

  @override
  void initState() {
    super.initState();
    // Initialize the stream to get real-time data
    _refreshData();
  }

  void _refreshData() {
    // Initialize the stream for real-time updates
    barang = supabase.from('product').stream(primaryKey: ['id']);
    setState(() {}); // Ensure the UI rebuilds
  }

  // Call this after deleting or navigating back from Insert/Update screens
  Future<void> deleteItem(String id) async {
    final response = await supabase.from('product').delete().eq('id', id);
    if (response.error != null) {
      _showSnackbar('Error deleting item: ${response.error!.message}');
    } else {
      _showSnackbar('Item deleted successfully');
      _refreshData(); // Refresh after deletion
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshData(); // Manual refresh when clicking the button
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding:
            const EdgeInsets.only(bottom: 20), // Adjust this value as needed
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.extended(
              onPressed: () async {
                // Navigate to the Insert Product screen and refresh when returning
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InsertBarang()),
                );
                _refreshData(); // Auto-refresh after adding a product
              },
              label: const Text('Add Product'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: barang,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return const Center(child: CircularProgressIndicator());
            }

            final products = snapshot.data!;

            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final productId = product['id'].toString();
                final productName = product['name'] ?? 'No Name';
                final productDescription =
                    product['description'] ?? 'No Description';
                final productPrice = product['price']?.toString() ?? 'No Price';
                final productStock = product['stock']?.toString() ?? 'No Stock';
                final productImageUrl = product['imageurl'] ?? '';
                final categoryName = product['category'] ?? 'No Category';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            productImageUrl.isNotEmpty
                                ? Image.network(
                                    productImageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image,
                                    size: 80,
                                    color: Colors.grey), // Placeholder
                            const SizedBox(width: 10),
                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    productDescription,
                                    style: TextStyle(color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text('Category: $categoryName'),
                                  Text(
                                      'Price: Rp. ${NumberFormat("#,##0", "en_ID").format(int.parse(productPrice))}'),
                                  Text('Stock: $productStock'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () async {
                                bool updateConfirmed = await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Update item'),
                                      content: const Text(
                                          'Are you sure you want to update this item?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text('Update'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (updateConfirmed) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UpdateBarang(productId: productId),
                                    ),
                                  );
                                  _refreshData(); // Auto-refresh after updating a product
                                }
                              },
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              onPressed: () async {
                                bool deleteConfirmed = await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete item'),
                                      content: const Text(
                                          'Are you sure you want to delete this item?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (deleteConfirmed) {
                                  await deleteItem(productId);
                                }
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
