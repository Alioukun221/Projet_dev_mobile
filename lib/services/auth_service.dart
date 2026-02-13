import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Current user
  User? get currentUser => _client.auth.currentUser;

  // Current session
  Session? get currentSession => _client.auth.currentSession;

  // Is logged in
  bool get isLoggedIn => currentUser != null;

  // Auth state stream
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // Sign up with email
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
    return response;
  }

  // Sign in with email
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Get user profile from profiles table
  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? preferredLocale,
    String? preferredTheme,
    String? currency,
    String? avatar,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (preferredLocale != null) updates['preferred_locale'] = preferredLocale;
    if (preferredTheme != null) updates['preferred_theme'] = preferredTheme;
    if (currency != null) updates['currency'] = currency;
    if (avatar != null) updates['avatar'] = avatar;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', user.id);
    }
  }
}
