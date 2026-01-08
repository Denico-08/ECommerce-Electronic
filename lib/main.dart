import 'package:KlikGadget/start.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/constant/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

  try {
    await Supabase.initialize(
      url: supabaseURL,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    // Handle Supabase initialization errors
    print('Error initializing Supabase: $e');
    // You might want to display an error message to the user or implement a retry mechanism here.
  }

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Supabase Flutter',
      debugShowCheckedModeBanner: false,
      home: Start(),
    );
  }
}
