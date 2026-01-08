// ignore_for_file: unused_catch_clause

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/main.dart'; // Assuming supabase is available here

class AuthService {
  Future<void> signUp(String email, String password, String username) async {
    try {
      final credentials = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = credentials.user?.id;

      await supabase.from('users').insert([
        {
          'id': userId,
          'username': username,
          'email': email,
          'isAdmin': false,
          'profilepicture': null,
          'saldo': 0
        },
      ]);
    } on AuthException catch (error) {
      // Handle AuthExceptions and rethrow for the UI to handle
      rethrow;
    } catch (error) {
      // Handle other unexpected errors and rethrow
      throw Exception('Unexpected error occurred');
    }
  }
}
