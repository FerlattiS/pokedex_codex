import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_codex/services/supabase_service.dart';

void main() {
  test('Supabase config is disabled without credentials', () {
    const config = SupabaseConfig(url: '', publishableKey: '');

    expect(config.isConfigured, isFalse);
  });

  test('Supabase config is enabled with url and publishable key', () {
    const config = SupabaseConfig(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_example',
    );

    expect(config.isConfigured, isTrue);
  });
}
