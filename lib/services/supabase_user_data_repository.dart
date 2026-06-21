import 'package:supabase/supabase.dart';

import '../models/user_pokemon_data.dart';
import 'user_data_repository.dart';

class SupabaseUserDataRepository implements UserDataRepository {
  SupabaseUserDataRepository({required this.client, required this.userId});

  static const favoritesTable = 'favorite_pokemon';
  static const notesTable = 'pokemon_notes';
  static const teamsTable = 'pokemon_teams';

  final SupabaseClient client;
  final String userId;

  @override
  Future<Set<int>> readFavoritePokemonIds() async {
    final rows = await client
        .from(favoritesTable)
        .select('pokemon_id')
        .eq('user_id', userId)
        .order('pokemon_id', ascending: true);

    return rows.map((row) => row['pokemon_id'] as int).toSet();
  }

  @override
  Future<void> writeFavoritePokemonIds(Set<int> pokemonIds) async {
    await client.from(favoritesTable).delete().eq('user_id', userId);

    if (pokemonIds.isEmpty) {
      return;
    }

    final rows = pokemonIds.map(favoritePokemonRow).toList();
    await client.from(favoritesTable).insert(rows);
  }

  @override
  Future<List<PokemonNote>> readNotes() async {
    final rows = await client
        .from(notesTable)
        .select('pokemon_id,note,updated_at')
        .eq('user_id', userId)
        .order('pokemon_id', ascending: true);

    return rows.map(noteFromRow).toList();
  }

  @override
  Future<void> writeNote(PokemonNote note) async {
    await client
        .from(notesTable)
        .upsert(noteToRow(note), onConflict: 'user_id,pokemon_id');
  }

  @override
  Future<void> deleteNote(int pokemonId) async {
    await client
        .from(notesTable)
        .delete()
        .eq('user_id', userId)
        .eq('pokemon_id', pokemonId);
  }

  @override
  Future<List<PokemonTeam>> readTeams() async {
    final rows = await client
        .from(teamsTable)
        .select('id,name,pokemon_ids,updated_at')
        .eq('user_id', userId)
        .order('name', ascending: true);

    return rows.map(teamFromRow).toList();
  }

  @override
  Future<void> writeTeam(PokemonTeam team) async {
    await client
        .from(teamsTable)
        .upsert(teamToRow(team), onConflict: 'user_id,id');
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await client
        .from(teamsTable)
        .delete()
        .eq('user_id', userId)
        .eq('id', teamId);
  }

  Map<String, dynamic> favoritePokemonRow(int pokemonId) {
    return {'user_id': userId, 'pokemon_id': pokemonId};
  }

  Map<String, dynamic> noteToRow(PokemonNote note) {
    return {
      'user_id': userId,
      'pokemon_id': note.pokemonId,
      'note': note.text,
      'updated_at': note.updatedAt.toIso8601String(),
    };
  }

  static PokemonNote noteFromRow(Map<String, dynamic> row) {
    return PokemonNote(
      pokemonId: row['pokemon_id'] as int,
      text: row['note'] as String,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> teamToRow(PokemonTeam team) {
    return {
      'id': team.id,
      'user_id': userId,
      'name': team.name,
      'pokemon_ids': team.pokemonIds,
      'updated_at': team.updatedAt.toIso8601String(),
    };
  }

  static PokemonTeam teamFromRow(Map<String, dynamic> row) {
    return PokemonTeam(
      id: row['id'] as String,
      name: row['name'] as String,
      pokemonIds: (row['pokemon_ids'] as List<dynamic>).cast<int>(),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
