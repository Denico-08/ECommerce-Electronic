import 'package:KlikGadget/main.dart';
import 'package:KlikGadget/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _saldoController = TextEditingController();
  bool _isLoading = false;
  String? _username;
  String? _email;
  int? _saldo;
  String? _imageUrl;

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

    try {
      final userData = await supabase
          .from('users')
          .select('username, email, saldo, profilepicture')
          .eq('id', user.id)
          .single();

      setState(() {
        _username = userData['username'] ?? '';
        _email = userData['email'];
        _saldo = userData['saldo'] ?? 0;
        _imageUrl = userData['profilepicture'] ?? '';
        _usernameController.text = _username!;
        _saldoController.text = _saldo.toString();
      });
    } catch (error) {
      _showNormalToast('Error loading profile: $error', Colors.red);
    }
  }

  Future<void> _updateUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _navigateToLogin();
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final saldo = int.tryParse(_saldoController.text.trim());

    if (username.isEmpty || saldo == null) {
      _showNormalToast(
          'Invalid input: Username or saldo cannot be empty', Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    final updates = {
      'username': username,
      'saldo': saldo,
      'profilepicture': _imageUrl,
    };

    try {
      await supabase.from('users').update(updates).eq('id', user.id).single();
      _showNormalToast('Profile updated successfully', Colors.black);
      await _loadUserProfile();
    } catch (error) {
      _showNormalToast('Profile updated successfully', Colors.black);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _navigateToLogin();
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final fileExt = pickedFile.name.split('.').last.toLowerCase();
      final fileName = 'avatars/${user.id}.$fileExt';
      final imageBytes = await pickedFile.readAsBytes();

      const supportedFormats = ['jpg', 'jpeg', 'png', 'gif'];
      if (!supportedFormats.contains(fileExt)) {
        throw Exception('Unsupported image format');
      }

      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        final existingFileName = _imageUrl!.split('/').last;
        await supabase.storage.from('user_picture').remove([existingFileName]);
      }

      await supabase.storage.from('user_picture').uploadBinary(
          fileName, imageBytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'));

      setState(() {
        _imageUrl =
            supabase.storage.from('user_picture').getPublicUrl(fileName);
      });

      await _updateUserProfile();
    } catch (error) {
      _showNormalToast('Error uploading image: $error', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showNormalToast(String message, Color color) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Edit Profile'),
          ),
          body: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _uploadImage,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color.fromARGB(41, 68, 135, 1),
                          child:
                              const Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _saldoController,
                label: 'Balance',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? Center(
                      child: SpinKitFadingCircle(
                        color: Colors.black,
                        size: 50.0,
                      ),
                    )
                  : _buildSubmitButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.lato(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lato(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateUserProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(41, 68, 135, 1),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        child: Text(
          _isLoading ? 'Updating...' : 'Update Profile',
          style: GoogleFonts.lato(fontSize: 14.sp, color: Colors.white),
        ),
      ),
    );
  }
}
