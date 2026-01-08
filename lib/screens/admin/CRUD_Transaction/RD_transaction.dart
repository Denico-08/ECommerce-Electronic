// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminTransaction extends StatefulWidget {
  const AdminTransaction({super.key});

  @override
  State<AdminTransaction> createState() => _AdminTransactionState();
}

class _AdminTransactionState extends State<AdminTransaction> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Stream for order_items
  late final Stream<List<Map<String, dynamic>>> barang;

  @override
  void initState() {
    super.initState();
    barang = supabase.from('order_items').stream(primaryKey: ['id']);
  }

  // Fetch order details
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await supabase
          .from('orders')
          .select('*, shipping_address:address(alamat), order_items(*, product_vars:product_vars(*, product:product(name)))')
          .eq('id', orderId)
          .single();

      if (response == null) {
        throw Exception('No data found for order ID: $orderId');
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }

  // Delete item method
  Future<void> deleteItem(int id) async {
    try {
      await supabase.from('order_items').delete().eq('id', id);
      _showSnackbar('Item deleted successfully');
    } catch (e) {
      _showSnackbar('Error deleting item: $e');
    }
  }

  // Update order status with current timestamp
  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status_order': newStatus})
          .eq('id', orderId);

      _showSnackbar('Status updated successfully');
    } catch (e) {
      _showSnackbar('Error updating status: $e');
    }
  }

  // Show Snackbar
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Transactions'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: barang,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No orders available'));
            }

            final orders = snapshot.data!;

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final orderItem = orders[index];
                final orderId = int.parse(orderItem['order_id'].toString());

                return FutureBuilder<Map<String, dynamic>>(
                  future: getOrderDetails(orderId),
                  builder: (context, detailsSnapshot) {
                    if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (detailsSnapshot.hasError) {
                      return Center(child: Text('Error: ${detailsSnapshot.error}'));
                    }

                    if (!detailsSnapshot.hasData) {
                      return const Center(child: Text('No details available'));
                    }

                    final orderDetails = detailsSnapshot.data!;
                    final productname = orderDetails['order_items'][0]['product_vars']['product']['name'] ?? 'Unknown';
                    final productAmount = orderDetails['total_amount'].toString();
                    final shippingAddress = orderDetails['shipping_address']['alamat'] ?? 'No address';
                    final currentStatus = orderDetails['status_order'] ?? 'Pending';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount: $productAmount',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text('Product: $productname'),
                            Text('Address: $shippingAddress'),
                            Text('Current Status: $currentStatus'),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DropdownButton<String>(
                                  value: currentStatus,
                                  items: const [
                                    DropdownMenuItem(value: 'dikemas', child: Text('Dikemas')),
                                    DropdownMenuItem(value: 'diantar', child: Text('Diantar')),
                                    DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                                  ],
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      updateOrderStatus(orderId, newValue);
                                    }
                                  },
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final deleteConfirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Delete item'),
                                          content: const Text('Are you sure you want to delete this item?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (deleteConfirmed == true) {
                                      await deleteItem(orderId);
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
            );
          },
        ),
      ),
    );
  }
}
