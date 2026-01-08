// ignore_for_file: unused_field

import 'package:KlikGadget/main.dart';
import 'package:KlikGadget/screens/user/Profile/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:KlikGadget/screens/login.dart';
import 'package:KlikGadget/screens/user/Profile/user_address.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  String? _email;
  int? _saldo;
  String? _imageUrl;
  String? _shippingAddress; // Variable to store shipping address
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      _navigateToLogin();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await supabase
          .from('users')
          .select('username, email, saldo, profilepicture')
          .eq('id', user.id)
          .single();

      setState(() {
        _username = userData['username'] ?? 'User';
        _email = userData['email'];
        _saldo = userData['saldo'] ?? 0;
        _imageUrl = userData['profilepicture'] ?? '';
      });

      // Load shipping address
      await _loadShippingAddress(user.id); // Load address using user ID
    } catch (error) {
      _showErrorSnackBar('Error loading profile: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadShippingAddress(String userId) async {
    try {
      final response = await supabase
          .from('address')
          .select('alamat')
          .eq('user_id', userId)
          .order('id',
              ascending: true) // Order by ID or any other column you want
          .limit(1) // Limit to one address
          .maybeSingle(); // Using maybeSingle() to avoid exceptions

      setState(() {
        // If the response is null or empty, set to placeholder
        _shippingAddress =
            response?['alamat'] as String? ?? 'No address available';
      });
    } catch (error) {
      print('Error loading address: $error');
      // If an error occurs, set to placeholder
      setState(() {
        _shippingAddress = 'No address available';
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _refreshUserProfile() {
    _loadUserProfile();
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      _navigateToLogin();
    } catch (error) {
      _showErrorSnackBar('Error during logout: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Profile",
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Message
                  Text(
                    'Welcome, ${_username ?? 'User'}!',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Picture
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : const NetworkImage(
                              'https://imgur.com/a/RFHvxwp',
                            ),
                    ),
                  ),

                  // Refresh Button
                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.grey),
                      onPressed: _isLoading ? null : _refreshUserProfile,
                    ),
                  ),

                  const SizedBox(height: 10),
                  // Username Display
                  _buildProfileItem(
                    label: 'Username',
                    value: _username ?? 'user@example.com',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),

                  // Shipping Address
                  _buildProfileItem(
                    label: 'Shipping Addresses',
                    value: _shippingAddress ??
                        'No address available', // Placeholder
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserAddress(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    label: 'Balance',
                    value:
                        '${NumberFormat.currency(locale: 'id', symbol: 'Rp. ').format(_saldo ?? 0)}',
                  ),
                  // Profile Update Info
                  Text(
                    "To update your profile and balance tap (Username > )\nTo add shipping address tap (Shipping Address > )",
                    style: GoogleFonts.lato(color: Colors.grey),
                  ),
                  const SizedBox(height: 20), // Add spacing
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(41, 68, 135, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isLoading ? 'Log Out...' : "LOGOUT",
                        style: GoogleFonts.lato(
                            fontWeight: FontWeight.normal,
                            fontSize: 17,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem(
      {required String label, required String value, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label, style: GoogleFonts.lato(color: Colors.grey)),
            subtitle: Text(
              value,
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: onTap != null
                ? const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey)
                : null,
          ),
        ),
      ),
    );
  }
}
