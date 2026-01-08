// ignore_for_file: unnecessary_null_comparison

import 'package:KlikGadget/screens/admin/CRUD_Product/RD_product.dart';
import 'package:KlikGadget/screens/admin/CRUD_User/RUD_user.dart';
import 'package:KlikGadget/screens/admin/CRUD_Transaction/RD_transaction.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/main.dart';
import 'package:KlikGadget/screens/login.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? _username;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  Future<void> _getUsername() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        print('User ID: ${user.id}');

        final response = await supabase
            .from('users')
            .select('username')
            .eq('id', user.id)
            .single();

        print('Response: $response');

        if (response != null && response['username'] != null) {
          setState(() {
            _username = response['username'] as String? ?? 'Guest';
            print('Username: $_username');
          });
        } else {
          context.showErrorSnackBar(message: 'User data not found');
        }
      } else {
        print('User is not authenticated');
        context.showErrorSnackBar(message: 'User is not authenticated');
      }
    } on AuthException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (e) {
      context.showErrorSnackBar(message: 'Unexpected error occurred');
      print(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 32),
                  Text('Welcome, $_username'),
                  const SizedBox(height: 32),
                  _buildAdminCard('View Products', Icons.shopping_cart, () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const Admin_Barang(),
                    ));
                  }),
                  _buildAdminCard('View Users', Icons.people, () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AdminCustomer(),
                    ));
                  }),
                  _buildAdminCard('View Transactions', Icons.monetization_on,
                      () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AdminTransaction(),
                    ));
                  }),
                  ElevatedButton(
                    onPressed: () async {
                      await supabase.auth.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ));
                      }
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

extension on BuildContext {
  void showErrorSnackBar({required String message}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
