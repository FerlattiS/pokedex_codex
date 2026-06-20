import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_pokemon_data.dart';

abstract class UserDataRepository {
  Future<Set<int>> readFavoritePokemonIds();

  Future<void> writeFavoritePokemonIds(Set<int> pokemonIds);

  Future<List<PokemonNote>> readNotes();

  Future<void> writeNote(PokemonNote note);

  Future<void> deleteNote(int pokemonId);

  Future<List<PokemonTeam>> readTeams();

  Future<void> writeTeam(PokemonTeam team);

  Future<void> deleteTeam(String teamId);
}

class LocalUserDataRepository implements UserDataRepository {
  LocalUserDataRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _favoritesKey = 'user.data.favoritePokemonIds';
  static const _notesKey = 'user.data.notes';
  static const _teamsKey = 'user.data.teams';

  @override
  Future<Set<int>> readFavoritePokemonIds() async {
    final values = _preferences.getStringList(_favoritesKey) ?? [];

    return values.map(int.parse).toSet();
  }

  @override
  Future<void> writeFavoritePokemonIds(Set<int> pokemonIds) async {
    final values = pokemonIds.map((id) => '$id').toList()..sort();
    await _preferences.setStringList(_favoritesKey, values);
  }

  @override
  Future<List<PokemonNote>> readNotes() async {
    final rawValue = _preferences.getString(_notesKey);
    if (rawValue == null) {
      return [];
    }

    final data = jsonDecode(rawValue) as List<dynamic>;

    return data.cast<Map<String, dynamic>>().map(PokemonNote.fromJson).toList();
  }

  @override
  Future<void> writeNote(PokemonNote note) async {
    final notes = await readNotes();
    final nextNotes = [
      for (final item in notes)
        if (item.pokemonId != note.pokemonId) item,
      note,
    ]..sort((first, second) => first.pokemonId.compareTo(second.pokemonId));

    await _writeNotes(nextNotes);
  }

  @override
  Future<void> deleteNote(int pokemonId) async {
    final notes = await readNotes();
    await _writeNotes([
      for (final note in notes)
        if (note.pokemonId != pokemonId) note,
    ]);
  }

  @override
  Future<List<PokemonTeam>> readTeams() async {
    final rawValue = _preferences.getString(_teamsKey);
    if (rawValue == null) {
      return [];
    }

    final data = jsonDecode(rawValue) as List<dynamic>;

    return data.cast<Map<String, dynamic>>().map(PokemonTeam.fromJson).toList();
  }

  @override
  Future<void> writeTeam(PokemonTeam team) async {
    final teams = await readTeams();
    final nextTeams = [
      for (final item in teams)
        if (item.id != team.id) item,
      team,
    ]..sort((first, second) => first.name.compareTo(second.name));

    await _writeTeams(nextTeams);
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    final teams = await readTeams();
    await _writeTeams([
      for (final team in teams)
        if (team.id != teamId) team,
    ]);
  }

  Future<void> _writeNotes(List<PokemonNote> notes) async {
    await _preferences.setString(
      _notesKey,
      jsonEncode(notes.map((note) => note.toJson()).toList()),
    );
  }

  Future<void> _writeTeams(List<PokemonTeam> teams) async {
    await _preferences.setString(
      _teamsKey,
      jsonEncode(teams.map((team) => team.toJson()).toList()),
    );
  }
}

class MemoryUserDataRepository implements UserDataRepository {
  final Set<int> _favoritePokemonIds = {};
  final Map<int, PokemonNote> _notes = {};
  final Map<String, PokemonTeam> _teams = {};

  @override
  Future<Set<int>> readFavoritePokemonIds() async {
    return {..._favoritePokemonIds};
  }

  @override
  Future<void> writeFavoritePokemonIds(Set<int> pokemonIds) async {
    _favoritePokemonIds
      ..clear()
      ..addAll(pokemonIds);
  }

  @override
  Future<List<PokemonNote>> readNotes() async {
    return _notes.values.toList()
      ..sort((first, second) => first.pokemonId.compareTo(second.pokemonId));
  }

  @override
  Future<void> writeNote(PokemonNote note) async {
    _notes[note.pokemonId] = note;
  }

  @override
  Future<void> deleteNote(int pokemonId) async {
    _notes.remove(pokemonId);
  }

  @override
  Future<List<PokemonTeam>> readTeams() async {
    return _teams.values.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
  }

  @override
  Future<void> writeTeam(PokemonTeam team) async {
    _teams[team.id] = team;
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    _teams.remove(teamId);
  }
}
