import 'package:supabase_flutter/supabase_flutter.dart';

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

Future<SupabaseClient?> initializeSupabase({
  SupabaseConfig config = const SupabaseConfig(),
}) async {
  if (!config.isConfigured) {
    return null;
  }

  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
  );

  return Supabase.instance.client;
}
