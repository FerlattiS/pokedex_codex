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

  test('Stores Pokedle settings and results locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalPokedleProgressRepository(preferences);

    await repository.writeSettings(
      const PokedleSettings(
        dexScope: PokedleDexScope.full,
        attemptMode: PokedleAttemptMode.easy,
      ),
    );
    await repository.writeResult(
      PokedleDailyResult(
        sessionKey: '2026-06-22.full.easy',
        dateKey: '2026-06-22',
        dexScope: PokedleDexScope.full,
        attemptMode: PokedleAttemptMode.easy,
        targetId: 1,
        won: true,
        attempts: 2,
        completedAt: DateTime(2026, 6, 22),
      ),
    );

    final settings = await repository.readSettings();
    final result = await repository.readResult('2026-06-22.full.easy');
    final results = await repository.readResults();

    expect(settings.dexScope, PokedleDexScope.full);
    expect(settings.attemptMode, PokedleAttemptMode.easy);
    expect(result?.won, isTrue);
    expect(result?.attempts, 2);
    expect(results, hasLength(1));
  });
}
