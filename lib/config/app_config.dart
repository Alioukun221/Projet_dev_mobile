import 'package:flutter/material.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const googleWebClientId =
      '520323381500-ototpv8bjqv44vfs1744lvmrs8kf4d1j.apps.googleusercontent.com';

  static String get supabaseAnonKey =>
      _supabaseAnonKey.isNotEmpty ? _supabaseAnonKey : _supabasePublishableKey;

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static void debugEnvironment() {
    debugPrint('SUPABASE_URL présente: ${supabaseUrl.isNotEmpty}');
    debugPrint(
      'SUPABASE_ANON_KEY présente: ${_supabaseAnonKey.isNotEmpty}',
    );
    debugPrint(
      'SUPABASE_PUBLISHABLE_KEY présente: '
      '${_supabasePublishableKey.isNotEmpty}',
    );
  }
}
