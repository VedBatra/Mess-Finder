import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mess_finder/utils/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  final client = Supabase.instance.client;

  print('Attempting to create demo user...');
  try {
    await client.auth.signUp(
      email: 'user@demo.com',
      password: 'password123',
      data: {
        'full_name': 'Demo User',
        'role': 'user',
      },
    );
    print('✅ Demo User created successfully (or already exists)!');
  } catch (e) {
    print('⚠️ Note on Demo User: $e');
  }

  print('Attempting to create demo owner...');
  try {
    await client.auth.signUp(
      email: 'owner@demo.com',
      password: 'password123',
      data: {
        'full_name': 'Demo Owner',
        'role': 'owner',
      },
    );
    print('✅ Demo Owner created successfully (or already exists)!');
  } catch (e) {
    print('⚠️ Note on Demo Owner: $e');
  }

  print('\nDone! You can now close this and run the main app.');
}
