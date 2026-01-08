import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class UserAddress extends StatefulWidget {
  const UserAddress({super.key});

  @override
  State<UserAddress> createState() => _UserAddressState();
}

class _UserAddressState extends State<UserAddress> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController kota = TextEditingController();
  final TextEditingController provinsi = TextEditingController();
  final TextEditingController alamat = TextEditingController();
  bool isLoading = false;

  Future<void> addToAddress() async {
    final session = supabase.auth.currentSession;

    if (session != null) {
      setState(() => isLoading = true);

      final userId = session.user.id;
      final city = kota.text;
      final province = provinsi.text;
      final address = alamat.text;

      if (city.isEmpty || province.isEmpty || address.isEmpty) {
        _showSnackbar('Please fill in all fields correctly.');
        setState(() => isLoading = false);
        return;
      }

      final alamatUser = '$city, $province, $address';

      try {
        await supabase.from('address').insert({
          'user_id': userId,
          'alamat': alamatUser,
        });

        _showSnackbar('Successfully added address.');
      } on PostgrestException catch (e) {
        _showSnackbar('Error: ${e.message}');
      } catch (e) {
        _showSnackbar('Failed to add address.');
      }

      setState(() => isLoading = false);
    } else {
      _showSnackbar('User is not logged in.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('User Address'),
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildUnderlineTextField(
                    controller: kota,
                    label: 'City',
                    validationMessage: 'Please insert your "City" column',
                  ),
                  _buildUnderlineTextField(
                    controller: provinsi,
                    label: 'Province',
                    validationMessage: 'Please insert your "Province" column',
                  ),
                  _buildUnderlineTextField(
                    controller: alamat,
                    label: 'Complete Address',
                    validationMessage: 'The address cannot be empty',
                  ),
                  SizedBox(height: 30.h),
                  isLoading
                      ? Center(
                          child: SpinKitCircle(
                            color: Colors.black,
                            size: 50.0,
                          ),
                        )
                      : _buildSubmitButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String label,
    required String validationMessage,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: TextFormField(
        controller: controller,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validationMessage;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          'Save',
          style: GoogleFonts.lato(fontSize: 18.sp, color: Colors.white),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      addToAddress();
    }
  }
}
