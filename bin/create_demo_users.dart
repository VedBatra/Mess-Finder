import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mess_finder/utils/supabase_config.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  final client = Supabase.instance.client;

  print('Creating demo user...');
  try {
    await client.auth.signUp(
      email: 'user@demo.com',
      password: 'password123',
      data: {
        'full_name': 'Demo User',
        'role': 'user',
      },
    );
    print('Demo User Created!');
  } catch (e) {
    print('Error creating demo user: $e');
  }

  print('Creating demo owner...');
  try {
    await client.auth.signUp(
      email: 'owner@demo.com',
      password: 'password123',
      data: {
        'full_name': 'Demo Owner',
        'role': 'owner',
      },
    );
    print('Demo Owner Created!');
  } catch (e) {
    print('Error creating demo owner: $e');
  }

  print('Done!');
}
