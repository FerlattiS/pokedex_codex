import 'package:flutter/material.dart';

import '../services/game_results_repository.dart';
import '../services/pokedle_progress_repository.dart';
import '../services/user_data_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userDataRepository,
    required this.pokedleProgressRepository,
    required this.gameResultsRepository,
    required this.isSupabaseConfigured,
  });

  final UserDataRepository userDataRepository;
  final PokedleProgressRepository pokedleProgressRepository;
  final GameResultsRepository gameResultsRepository;
  final bool isSupabaseConfigured;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<_ProfileStats> _statsFuture = _loadStats();

  Future<_ProfileStats> _loadStats() async {
    final favorites = await widget.userDataRepository.readFavoritePokemonIds();
    final notes = await widget.userDataRepository.readNotes();
    final teams = await widget.userDataRepository.readTeams();
    final pokedleResults = await widget.pokedleProgressRepository.readResults();
    final gameResults = await widget.gameResultsRepository.readResults();

    return _ProfileStats(
      favoriteCount: favorites.length,
      noteCount: notes.length,
      teamCount: teams.length,
      pokedleStats: _PokedleProfileStats.fromResults(pokedleResults),
      gameStats: _GameProfileStats.fromResults(gameResults),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.person_outline), text: 'General'),
                  Tab(icon: Icon(Icons.catching_pokemon), text: 'Pokedle'),
                  Tab(
                    icon: Icon(Icons.sports_esports_outlined),
                    text: 'Juegos',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Entrenador',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 36,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Invitado',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.isSupabaseConfigured
                                            ? 'Supabase configurado, login pendiente'
                                            : 'Modo local sin Supabase configurado',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Resumen',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState != ConnectionState.done)
                          const Center(child: CircularProgressIndicator())
                        else
                          _StatsGrid(stats: stats ?? _ProfileStats.empty()),
                        const SizedBox(height: 24),
                        Text(
                          'Cuenta',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  widget.isSupabaseConfigured
                                      ? Icons.cloud_done_outlined
                                      : Icons.cloud_off_outlined,
                                ),
                                title: Text(
                                  widget.isSupabaseConfigured
                                      ? 'Backend disponible'
                                      : 'Backend no configurado',
                                ),
                                subtitle: const Text(
                                  'El perfil se sincronizara cuando agreguemos autenticacion.',
                                ),
                              ),
                              const Divider(height: 1),
                              const ListTile(
                                leading: Icon(Icons.badge_outlined),
                                title: Text('Perfil remoto'),
                                subtitle: Text(
                                  'Preparado para nombre, titulo de entrenador y preferencias.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Pokedle',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState != ConnectionState.done)
                          const Center(child: CircularProgressIndicator())
                        else
                          _PokedleProfileSection(
                            stats:
                                stats?.pokedleStats ??
                                _PokedleProfileStats.empty(),
                          ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Juegos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState != ConnectionState.done)
                          const Center(child: CircularProgressIndicator())
                        else
                          _GamesProfileSection(
                            stats:
                                stats?.gameStats ?? _GameProfileStats.empty(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _StatTile(label: 'Favoritos', value: stats.favoriteCount),
        _StatTile(label: 'Notas', value: stats.noteCount),
        _StatTile(label: 'Equipos', value: stats.teamCount),
      ],
    );
  }
}

class _PokedleProfileSection extends StatelessWidget {
  const _PokedleProfileSection({required this.stats});

  final _PokedleProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          children: [
            _StatTile(label: 'Partidas', value: stats.gamesPlayed),
            _StatTile(label: 'Victorias', value: stats.wins),
            _StatTile(label: 'Racha actual', value: stats.currentStreak),
            _StatTile(label: 'Mejor racha', value: stats.bestStreak),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.percent_outlined),
                title: const Text('Ratio de victoria'),
                trailing: Text('${stats.winRate}%'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.speed_outlined),
                title: const Text('Promedio de intentos ganados'),
                trailing: Text(stats.averageWinningAttempts),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ProfileStats {
  const _ProfileStats({
    required this.favoriteCount,
    required this.noteCount,
    required this.teamCount,
    required this.pokedleStats,
    required this.gameStats,
  });

  factory _ProfileStats.empty() {
    return _ProfileStats(
      favoriteCount: 0,
      noteCount: 0,
      teamCount: 0,
      pokedleStats: _PokedleProfileStats.empty(),
      gameStats: _GameProfileStats.empty(),
    );
  }

  final int favoriteCount;
  final int noteCount;
  final int teamCount;
  final _PokedleProfileStats pokedleStats;
  final _GameProfileStats gameStats;
}

class _GamesProfileSection extends StatelessWidget {
  const _GamesProfileSection({required this.stats});

  final _GameProfileStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.byGame.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.sports_esports_outlined),
          title: Text('Sin partidas registradas'),
          subtitle: Text('Los minijuegos van a aparecer aca al completarlos.'),
        ),
      );
    }

    return Column(
      children: [
        for (final entry in stats.byGame.entries) ...[
          _GameStatsCard(title: _gameTitle(entry.key), stats: entry.value),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _gameTitle(String gameId) {
    return switch (gameId) {
      'pokemon_questions' => '15 Preguntas',
      'higher_or_lower' => 'Higher or Lower',
      _ => gameId,
    };
  }
}

class _GameStatsCard extends StatelessWidget {
  const _GameStatsCard({required this.title, required this.stats});

  final String title;
  final _SingleGameStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              children: [
                _StatTile(label: 'Partidas', value: stats.gamesPlayed),
                _StatTile(label: 'Victorias', value: stats.wins),
                _StatTile(label: 'Mejor racha', value: stats.bestStreak),
                _StatTile(label: 'Mejor score', value: stats.bestScore),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameProfileStats {
  const _GameProfileStats({required this.byGame});

  factory _GameProfileStats.empty() {
    return const _GameProfileStats(byGame: {});
  }

  factory _GameProfileStats.fromResults(List<GameResult> results) {
    final grouped = <String, List<GameResult>>{};
    for (final result in results) {
      grouped.putIfAbsent(result.gameId, () => []).add(result);
    }

    return _GameProfileStats(
      byGame: {
        for (final entry in grouped.entries)
          entry.key: _SingleGameStats.fromResults(entry.value),
      },
    );
  }

  final Map<String, _SingleGameStats> byGame;
}

class _SingleGameStats {
  const _SingleGameStats({
    required this.gamesPlayed,
    required this.wins,
    required this.bestStreak,
    required this.bestScore,
  });

  factory _SingleGameStats.fromResults(List<GameResult> results) {
    final wins = results.where((result) => result.won).length;
    final bestStreak = results.fold<int>(
      0,
      (best, result) => result.streak > best ? result.streak : best,
    );
    final bestScore = results.fold<int>(
      0,
      (best, result) => result.score > best ? result.score : best,
    );

    return _SingleGameStats(
      gamesPlayed: results.length,
      wins: wins,
      bestStreak: bestStreak,
      bestScore: bestScore,
    );
  }

  final int gamesPlayed;
  final int wins;
  final int bestStreak;
  final int bestScore;
}

class _PokedleProfileStats {
  const _PokedleProfileStats({
    required this.gamesPlayed,
    required this.wins,
    required this.currentStreak,
    required this.bestStreak,
    required this.winRate,
    required this.averageWinningAttempts,
  });

  factory _PokedleProfileStats.empty() {
    return const _PokedleProfileStats(
      gamesPlayed: 0,
      wins: 0,
      currentStreak: 0,
      bestStreak: 0,
      winRate: 0,
      averageWinningAttempts: '-',
    );
  }

  factory _PokedleProfileStats.fromResults(List<PokedleDailyResult> results) {
    if (results.isEmpty) {
      return _PokedleProfileStats.empty();
    }

    final sortedResults = [
      ...results,
    ]..sort((first, second) => first.completedAt.compareTo(second.completedAt));
    final wins = sortedResults.where((result) => result.won).toList();
    var currentStreak = 0;
    for (final result in sortedResults.reversed) {
      if (!result.won) {
        break;
      }

      currentStreak += 1;
    }

    var runningStreak = 0;
    var bestStreak = 0;
    for (final result in sortedResults) {
      if (result.won) {
        runningStreak += 1;
        if (runningStreak > bestStreak) {
          bestStreak = runningStreak;
        }
      } else {
        runningStreak = 0;
      }
    }

    final averageAttempts = wins.isEmpty
        ? '-'
        : (wins.fold<int>(0, (sum, result) => sum + result.attempts) /
                  wins.length)
              .toStringAsFixed(1);

    return _PokedleProfileStats(
      gamesPlayed: sortedResults.length,
      wins: wins.length,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      winRate: ((wins.length / sortedResults.length) * 100).round(),
      averageWinningAttempts: averageAttempts,
    );
  }

  final int gamesPlayed;
  final int wins;
  final int currentStreak;
  final int bestStreak;
  final int winRate;
  final String averageWinningAttempts;
}
