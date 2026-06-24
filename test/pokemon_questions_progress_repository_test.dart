import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_codex/services/pokemon_questions_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Stores Pokemon questions state locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalPokemonQuestionsProgressRepository(preferences);
    const state = PokemonQuestionsGameState(
      sessionKey: '2026-06-21',
      askedQuestionIds: ['generation-1', 'type-Fuego'],
      guessIds: [4, 25],
    );

    await repository.writeState(state);
    final savedState = await repository.readState('2026-06-21');

    expect(savedState?.askedQuestionIds, ['generation-1', 'type-Fuego']);
    expect(savedState?.guessIds, [4, 25]);
  });

  test('Stores Pokemon questions interface preferences locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalPokemonQuestionsProgressRepository(preferences);

    await repository.writePreferences(
      const PokemonQuestionsPreferences(
        selectedCategory: 'Tipo',
        favoriteQuestionIds: ['type-Fuego', 'dual-type'],
      ),
    );

    final savedPreferences = await repository.readPreferences();
    expect(savedPreferences.selectedCategory, 'Tipo');
    expect(savedPreferences.favoriteQuestionIds, ['type-Fuego', 'dual-type']);
  });
}
