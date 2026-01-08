import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Map<String, dynamic>> notifications = [];
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  Map<int, String> lastStatuses = {}; // To track the last status for each order
  Timer? _pollingTimer; // Timer for polling

  @override
  void initState() {
    super.initState();
    getOrders(); // Initial fetch
    startPolling(); // Start polling for order updates
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel the polling when the widget is disposed
    super.dispose();
  }

  // Start the polling to check for order status updates
  void startPolling() {
    const pollingInterval = Duration(seconds: 30); // Poll every 30 seconds
    _pollingTimer = Timer.periodic(pollingInterval, (timer) {
      checkForOrderStatusUpdates(); // Call function to check updates
    });
  }

  // Check for order status updates
  Future<void> checkForOrderStatusUpdates() async {
    final session = _supabaseClient.auth.currentSession;

    if (session != null) {
      final userId = session.user.id;

      // Fetch transactions for the logged-in user
      final transaksiResponse = await _supabaseClient
          .from('transaksi')
          .select('order_items_id')
          .eq('user_id', userId);

      if (transaksiResponse.isNotEmpty) {
        final transactions = transaksiResponse as List<dynamic>;

        for (var transaction in transactions) {
          final orderItemsId = transaction['order_items_id'];

          // Fetch the latest status and product name using the order_items_id
          final orderItemResponse = await _supabaseClient
              .from('order_items')
              .select(
                  'orders(status_order), product_vars:product_vars(product(name))')
              .eq('id', orderItemsId);

          if (orderItemResponse.isNotEmpty) {
            final orderItemData = orderItemResponse as List<dynamic>;
            final newStatus = orderItemData[0]['orders']['status_order'];
            final productName =
                orderItemData[0]['product_vars']['product']['name'];

            // Check if status has changed
            if (lastStatuses[orderItemsId] != null &&
                lastStatuses[orderItemsId] != newStatus) {
              addNotification(newStatus, productName);
            }

            // Always update the last known status
            lastStatuses[orderItemsId] = newStatus;
          }
        }
      }
    }
  }

  // Fetch initial orders
  Future<void> getOrders() async {
    final session = _supabaseClient.auth.currentSession;

    if (session != null) {
      final userId = session.user.id;

      // Fetch transactions for the logged-in user
      final transaksiResponse = await _supabaseClient
          .from('transaksi')
          .select('order_items_id')
          .eq('user_id', userId);

      if (transaksiResponse.isNotEmpty) {
        final transactions = transaksiResponse as List<dynamic>;

        for (var transaction in transactions) {
          final orderItemsId = transaction['order_items_id'];

          // Fetch the status and product name using the order_items_id
          final orderItemResponse = await _supabaseClient
              .from('order_items')
              .select(
                  'orders(status_order), product_vars:product_vars(product(name))')
              .eq('id', orderItemsId);

          if (orderItemResponse.isNotEmpty) {
            final orderItemData = orderItemResponse as List<dynamic>;
            final status = orderItemData[0]['orders']['status_order'];
            final productName =
                orderItemData[0]['product_vars']['product']['name'];

            // Add a new notification for the initial status
            addNotification(status, productName);

            // Save the current status as the last known status
            lastStatuses[orderItemsId] = status;
          }
        }
      }
    }
  }

  // Add a new notification
  void addNotification(String status, String productName) {
    String title = '';
    String description = '';

    // Determine title and description based on order status
    switch (status) {
      case 'dikemas':
        title = 'Pesanan Dikemas';
        description = 'Pesanan Anda untuk $productName sedang dikemas.';
        break;
      case 'diantar':
        title = 'Pesanan Diantar';
        description =
            'Mohon bersabar, pesanan Anda untuk $productName sedang diantar.';
        break;
      case 'selesai':
        title = 'Pesanan Selesai';
        description = 'Pesanan Anda untuk $productName telah selesai.';
        break;
      default:
        return; // Skip if status does not match any known status
    }

    // Use setState to add the notification and trigger a UI rebuild
    setState(() {
      notifications.add({
        'title': title,
        'description': description,
        'time': DateTime.now().toString(),
        'icon': Icons.notifications,
      });

      // Sort notifications by time (latest first)
      notifications.sort((a, b) =>
          DateTime.parse(b['time']).compareTo(DateTime.parse(a['time'])));
    });
  }

  // Remove a notification
  void _removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          onPressed: () {
            getOrders(); // Refresh notifications
          },
        ),
        centerTitle: true,
        title: Text(
          "History Pesanan",
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text("No notifications available."),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return Slidable(
                  key: ValueKey(index),
                  startActionPane: ActionPane(
                    motion: const StretchMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _removeNotification(index),
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Remove',
                      ),
                    ],
                  ),
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Notification Icon
                          Icon(
                            notifications[index]['icon'],
                            size: 40,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 16),
                          // Notification Text Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notifications[index]['title'],
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(notifications[index]['description']),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(
                                      DateTime.parse(
                                          notifications[index]['time'])),
                                  style: GoogleFonts.lato(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 'X' Button to Remove Notification
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              _removeNotification(index); // Remove notification
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
