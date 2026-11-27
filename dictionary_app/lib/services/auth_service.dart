
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static User? get currentUser => _client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // Đăng ký
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: data,
    );
  }

  // Đăng nhập
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Đăng xuất
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
