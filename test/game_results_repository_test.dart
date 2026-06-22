import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_codex/services/game_results_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Stores generic game results locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalGameResultsRepository(preferences);
    final result = GameResult(
      id: 'pokemon_questions.2026-06-21',
      gameId: 'pokemon_questions',
      dateKey: '2026-06-21',
      won: true,
      score: 12,
      attempts: 2,
      streak: 1,
      completedAt: DateTime(2026, 6, 21),
      metadata: const {'targetId': '1'},
    );

    await repository.writeResult(result);
    final results = await repository.readResults();

    expect(results, hasLength(1));
    expect(results.single.gameId, 'pokemon_questions');
    expect(results.single.metadata['targetId'], '1');
  });
}
