import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:KlikGadget/screens/login.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _username;
  String? _email;
  String? _imageUrl; // To store the profile picture URL

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      // Handle case where user is not authenticated
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    try {
      final userData = await supabase
          .from('users')
          .select('*') // Select all columns
          .eq('id', user.id) // Filter by user ID
          .single(); // Expect a single row

      setState(() {
        _username = userData['username'] ?? '';
        _email = userData['email'] ?? '';
        _imageUrl = userData['profilepicture'] ?? '';
      });
    } on PostgrestException catch (error) {
      // Handle specific Postgrest errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading user profile: ${error.message}')),
        );
      }
    } catch (error) {
      // Check the type of error and handle it accordingly
      if (error is PostgrestException) {
        // Handle Postgrest errors specifically
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error loading user profile: ${error.message}')), // Use named argument
        );
      } else {
        // Handle other unexpected errors
        print('Error loading user profile: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to load user profile')), // Use named argument
        );
      }
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        // Handle case where user is not authenticated
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }

      final updates = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'profilepicture': _imageUrl,
      };

      final result =
          await supabase.from('users').update(updates).eq('id', user.id);

      if (result == null) {
        // Check for errors in the update result
        "Sukses jing";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } on PostgrestException catch (error) {
      // Handle specific Postgrest errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating user profile: ${error.message}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user profile')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out')),
      );
    }
  }

  Future<void> _uploadImage() async {
    final user = supabase.auth.currentUser;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      try {
        // Get the file extension
        final fileExt = pickedFile.name.split('.').last.toLowerCase();
        final fileName = 'avatars/${user?.id}.$fileExt';

        // Read the image data as bytes
        final imageBytes = await pickedFile.readAsBytes();

        // Validate file extension (optional)
        const supportedFormats = ['jpg', 'jpeg', 'png', 'gif'];
        if (!supportedFormats.contains(fileExt)) {
          throw Exception('Unsupported image format');
        }

        // If the user already has a profile picture, delete it first
        if (_imageUrl != null) {
          // Extract filename from URL
          final existingFileName = _imageUrl!.split('/').last;
          await supabase.storage
              .from('user_picture')
              .remove([existingFileName]);
        }

        // Upload the new image
        final response = await supabase.storage
            .from('user_picture')
            .uploadBinary(fileName, imageBytes,
                fileOptions: FileOptions(contentType: 'image/$fileExt'));

        // Handle potential PostgrestException here if applicable
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $response')),
          );
        }
      } on PostgrestException catch (e) {
        // Handle specific Postgrest errors if they might occur during upload
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Postgrest Error: ${e.message}')),
          );
        }
      } catch (e) {
        // Handle other unexpected errors
        print('Unexpected error occurred during image upload: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unexpected error occurred: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              // Make the profile picture tappable
              onTap: _uploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                child: _imageUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text('Username: $_username'),
            Text('Email: $_email'),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(41, 68, 135, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isLoading ? 'Updating...' : 'Update Profile'),
            ),
            ElevatedButton(
              onPressed: _signOut,
              child: Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
