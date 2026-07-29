import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendwise/config/app_config.dart';

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

  // Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    debugPrint('[Auth] Google sign-in start');

    final googleSignIn =
        GoogleSignIn(serverClientId: AppConfig.googleWebClientId);

    debugPrint('[Auth] Calling googleSignIn.signIn()...');
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('[Auth] Google sign-in cancelled by user');
      throw Exception('Google Sign-In annulé');
    }
    debugPrint('[Auth] Google user obtained: ${googleUser.email}');

    debugPrint('[Auth] Requesting authentication tokens...');
    final googleAuth = await googleUser.authentication;
    debugPrint('[Auth] idToken present: ${googleAuth.idToken != null}');
    debugPrint('[Auth] accessToken present: ${googleAuth.accessToken != null}');

    if (googleAuth.idToken == null) {
      debugPrint(
          '[Auth] ERROR: idToken is null — check Android OAuth client SHA-1');
      throw Exception('Google Sign-In: idToken manquant');
    }

    debugPrint('[Auth] Calling Supabase signInWithIdToken...');
    try {
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      debugPrint('[Auth] Supabase sign-in success — uid: ${response.user?.id}');

      // Pré-remplir display_name si profil sans nom (premier login Google)
      final user = response.user;
      if (user != null) {
        final profile = await getProfile();
        final hasName = profile?['display_name'] != null &&
            (profile!['display_name'] as String).isNotEmpty;
        if (!hasName) {
          final meta = user.userMetadata ?? {};
          final displayName = (meta['full_name'] as String?)?.trim() ??
              (meta['display_name'] as String?)?.trim() ??
              (meta['name'] as String?)?.trim() ??
              user.email?.split('@').first;
          if (displayName != null) {
            await _client
                .from('profiles')
                .update({'display_name': displayName}).eq('id', user.id);
            debugPrint('[Auth] display_name updated: $displayName');
          }
        }
      }

      return response;
    } catch (e) {
      debugPrint('[Auth] Supabase signInWithIdToken error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Get user profile from profiles table
  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      return await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      debugPrint('AuthService.getProfile: $e');
      return null;
    }
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
      try {
        await _client.from('profiles').update(updates).eq('id', user.id);
      } catch (e) {
        debugPrint('AuthService.updateProfile: $e');
      }
    }
  }
}
