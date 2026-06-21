import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_codex/models/user_pokemon_data.dart';
import 'package:pokedex_codex/services/supabase_user_data_repository.dart';
import 'package:supabase/supabase.dart';

void main() {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'sb_publishable_example',
  );
  final repository = SupabaseUserDataRepository(
    client: client,
    userId: 'user-1',
  );

  tearDownAll(() async {
    await client.dispose();
  });

  test('Maps favorite Pokemon ids to Supabase rows', () {
    expect(repository.favoritePokemonRow(25), {
      'user_id': 'user-1',
      'pokemon_id': 25,
    });
  });

  test('Maps notes to and from Supabase rows', () {
    final updatedAt = DateTime.utc(2026, 6, 21, 12);
    final note = PokemonNote(
      pokemonId: 6,
      text: 'Buen atacante especial.',
      updatedAt: updatedAt,
    );

    expect(repository.noteToRow(note), {
      'user_id': 'user-1',
      'pokemon_id': 6,
      'note': 'Buen atacante especial.',
      'updated_at': updatedAt.toIso8601String(),
    });

    final restored = SupabaseUserDataRepository.noteFromRow({
      'pokemon_id': 6,
      'note': 'Buen atacante especial.',
      'updated_at': updatedAt.toIso8601String(),
    });

    expect(restored.pokemonId, 6);
    expect(restored.text, 'Buen atacante especial.');
    expect(restored.updatedAt, updatedAt);
  });

  test('Maps teams to and from Supabase rows', () {
    final updatedAt = DateTime.utc(2026, 6, 21, 12);
    final team = PokemonTeam(
      id: 'team-1',
      name: 'Equipo Kanto',
      pokemonIds: [3, 6, 9],
      updatedAt: updatedAt,
    );

    expect(repository.teamToRow(team), {
      'id': 'team-1',
      'user_id': 'user-1',
      'name': 'Equipo Kanto',
      'pokemon_ids': [3, 6, 9],
      'updated_at': updatedAt.toIso8601String(),
    });

    final restored = SupabaseUserDataRepository.teamFromRow({
      'id': 'team-1',
      'name': 'Equipo Kanto',
      'pokemon_ids': [3, 6, 9],
      'updated_at': updatedAt.toIso8601String(),
    });

    expect(restored.id, 'team-1');
    expect(restored.name, 'Equipo Kanto');
    expect(restored.pokemonIds, [3, 6, 9]);
    expect(restored.updatedAt, updatedAt);
  });
}
