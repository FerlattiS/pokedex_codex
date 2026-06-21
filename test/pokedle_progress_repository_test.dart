import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_codex/services/pokedle_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Stores Pokedle guesses by date locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalPokedleProgressRepository(preferences);

    await repository.writeGuessIds('2026-06-22', [4, 1]);

    expect(await repository.readGuessIds('2026-06-22'), [4, 1]);
    expect(await repository.readGuessIds('2026-06-23'), isEmpty);
  });
}
