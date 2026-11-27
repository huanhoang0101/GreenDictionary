
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl =
      'https://udjicwvivfcoucfudwiu.supabase.co';

  static const String supabasePublishableKey =
      'sb_publishable_J1aP0FpknQ0t7BaB5aatPQ_bg7wGaFy';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
