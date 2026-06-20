import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_codex/models/user_pokemon_data.dart';
import 'package:pokedex_codex/services/user_data_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Stores favorite Pokemon ids locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalUserDataRepository(preferences);

    await repository.writeFavoritePokemonIds({1, 4, 7});

    expect(await repository.readFavoritePokemonIds(), {1, 4, 7});
  });

  test('Stores notes by Pokemon id locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalUserDataRepository(preferences);
    final updatedAt = DateTime(2026, 6, 19);

    await repository.writeNote(
      PokemonNote(
        pokemonId: 6,
        text: 'Buen atacante especial.',
        updatedAt: updatedAt,
      ),
    );

    final notes = await repository.readNotes();

    expect(notes, hasLength(1));
    expect(notes.first.pokemonId, 6);
    expect(notes.first.text, 'Buen atacante especial.');

    await repository.deleteNote(6);

    expect(await repository.readNotes(), isEmpty);
  });

  test('Stores Pokemon teams locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalUserDataRepository(preferences);
    final updatedAt = DateTime(2026, 6, 19);

    await repository.writeTeam(
      PokemonTeam(
        id: 'team-1',
        name: 'Equipo Kanto',
        pokemonIds: [3, 6, 9],
        updatedAt: updatedAt,
      ),
    );

    final teams = await repository.readTeams();

    expect(teams, hasLength(1));
    expect(teams.first.name, 'Equipo Kanto');
    expect(teams.first.pokemonIds, [3, 6, 9]);

    await repository.deleteTeam('team-1');

    expect(await repository.readTeams(), isEmpty);
  });
}
