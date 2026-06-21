import 'package:supabase/supabase.dart';

class SupabaseConfig {
  const SupabaseConfig({
    this.url = const String.fromEnvironment('SUPABASE_URL'),
    this.publishableKey = const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  });

  final String url;
  final String publishableKey;

  bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

SupabaseClient? initializeSupabase({
  SupabaseConfig config = const SupabaseConfig(),
}) {
  if (!config.isConfigured) {
    return null;
  }

  return SupabaseClient(config.url, config.publishableKey);
}
