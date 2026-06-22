import 'dart:math';

import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import '../services/game_results_repository.dart';
import '../services/pokemon_repository.dart';

class HigherOrLowerPage extends StatefulWidget {
  const HigherOrLowerPage({
    super.key,
    required this.pokemonRepository,
    required this.gameResultsRepository,
  });

  final PokemonRepository pokemonRepository;
  final GameResultsRepository gameResultsRepository;

  @override
  State<HigherOrLowerPage> createState() => _HigherOrLowerPageState();
}

class _HigherOrLowerPageState extends State<HigherOrLowerPage> {
  final Random _random = Random();
  late Future<void> _loadFuture = _loadRound();
  late final String _dateKey = _formatDateKey(DateTime.now());
  List<PokemonPreview> _catalog = [];
  PokemonPreview? _leftPokemon;
  PokemonPreview? _rightPokemon;
  bool? _lastGuessWasCorrect;
  var _streak = 0;
  var _bestStreak = 0;
  var _isRevealed = false;
  var _isLoadingNext = false;
  int? _selectedPokemonId;
  final List<_HigherLowerRound> _roundHistory = [];
  var _scope = _HigherLowerScope.full;
  var _metric = _HigherLowerMetric.total;

  Future<void> _loadRound({PokemonPreview? carryPokemon}) async {
    final fullCatalog = _catalog.isEmpty
        ? await widget.pokemonRepository.fetchPokemonCatalog()
        : _catalog;
    final catalog = fullCatalog.where(_isInScope).toList();
    if (catalog.length < 2) {
      throw Exception('Catalogo insuficiente');
    }

    PokemonPreview left;
    PokemonPreview right;

    if (carryPokemon == null) {
      var leftIndex = _random.nextInt(catalog.length);
      var rightIndex = _random.nextInt(catalog.length);
      while (rightIndex == leftIndex) {
        rightIndex = _random.nextInt(catalog.length);
      }

      left = await widget.pokemonRepository.fetchPokemonDetail(
        catalog[leftIndex].id,
      );
      right = await widget.pokemonRepository.fetchPokemonDetail(
        catalog[rightIndex].id,
      );
    } else {
      left = carryPokemon;
      var rightIndex = _random.nextInt(catalog.length);
      while (catalog[rightIndex].id == carryPokemon.id) {
        rightIndex = _random.nextInt(catalog.length);
      }

      right = await widget.pokemonRepository.fetchPokemonDetail(
        catalog[rightIndex].id,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _catalog = fullCatalog;
      _leftPokemon = left;
      _rightPokemon = right;
      _lastGuessWasCorrect = null;
      _isRevealed = false;
      _isLoadingNext = false;
      _selectedPokemonId = null;
    });
  }

  void _choose(PokemonPreview selected) {
    if (_isRevealed) {
      return;
    }

    final left = _leftPokemon;
    final right = _rightPokemon;
    if (left == null || right == null) {
      return;
    }

    final leftTotal = _battleStatTotal(left);
    final rightTotal = _battleStatTotal(right);
    final selectedTotal = selected.id == left.id ? leftTotal : rightTotal;
    final otherTotal = selected.id == left.id ? rightTotal : leftTotal;
    final isCorrect = selectedTotal >= otherTotal;
    final historyItem = _HigherLowerRound(
      left: left,
      right: right,
      selected: selected,
      winner: leftTotal >= rightTotal ? left : right,
      wasCorrect: isCorrect,
    );

    setState(() {
      _isRevealed = true;
      _lastGuessWasCorrect = isCorrect;
      _selectedPokemonId = selected.id;
      _roundHistory.insert(0, historyItem);
      if (_roundHistory.length > 8) {
        _roundHistory.removeLast();
      }
      _streak = isCorrect ? _streak + 1 : 0;
      if (_streak > _bestStreak) {
        _bestStreak = _streak;
      }
    });

    widget.gameResultsRepository.writeResult(
      GameResult(
        id: 'higher_or_lower.${DateTime.now().microsecondsSinceEpoch}',
        gameId: 'higher_or_lower',
        dateKey: _dateKey,
        won: isCorrect,
        score: isCorrect ? _streak : 0,
        attempts: 1,
        streak: isCorrect ? _streak : 0,
        completedAt: DateTime.now(),
        metadata: {
          'metric': _metric.label,
          'scope': _scope.label,
          'leftId': '${left.id}',
          'rightId': '${right.id}',
          'selectedId': '${selected.id}',
        },
      ),
    );
  }

  Future<void> _nextRound() async {
    if (_isLoadingNext) {
      return;
    }

    final carryPokemon = _isRevealed ? _nextCarryPokemon() : null;

    setState(() {
      _isLoadingNext = true;
      _loadFuture = _loadRound(carryPokemon: carryPokemon);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            _leftPokemon == null ||
            _rightPokemon == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo cargar Higher or Lower'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _nextRound,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Higher or Lower',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Elegi cual tiene mayor battle stats total',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _HigherLowerSettings(
              scope: _scope,
              metric: _metric,
              onScopeChanged: (scope) => _changeSettings(scope: scope),
              onMetricChanged: (metric) => _changeSettings(metric: metric),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreChip(label: 'Racha', value: _streak),
                const SizedBox(width: 8),
                _ScoreChip(label: 'Mejor', value: _bestStreak),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 640;
                final leftCard = _HigherLowerCard(
                  pokemon: _leftPokemon!,
                  isRevealed: _isRevealed,
                  total: _battleStatTotal(_leftPokemon!),
                  isBestMatch:
                      _battleStatTotal(_leftPokemon!) >=
                      _battleStatTotal(_rightPokemon!),
                  isSelected: _selectedPokemonId == _leftPokemon!.id,
                  onChoose: () => _choose(_leftPokemon!),
                );
                final rightCard = _HigherLowerCard(
                  pokemon: _rightPokemon!,
                  isRevealed: _isRevealed,
                  total: _battleStatTotal(_rightPokemon!),
                  isBestMatch:
                      _battleStatTotal(_rightPokemon!) >=
                      _battleStatTotal(_leftPokemon!),
                  isSelected: _selectedPokemonId == _rightPokemon!.id,
                  onChoose: () => _choose(_rightPokemon!),
                );
                const separator = Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('VS'),
                );

                if (isNarrow) {
                  return Column(children: [leftCard, separator, rightCard]);
                }

                return Row(
                  children: [
                    Expanded(child: leftCard),
                    separator,
                    Expanded(child: rightCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (_lastGuessWasCorrect != null)
              _ResultBanner(isCorrect: _lastGuessWasCorrect!),
            if (_roundHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              _HigherLowerHistory(rounds: _roundHistory),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isRevealed ? _nextRound : null,
              icon: const Icon(Icons.navigate_next),
              label: const Text('Siguiente'),
            ),
          ],
        );
      },
    );
  }

  int _battleStatTotal(PokemonPreview pokemon) {
    if (_metric == _HigherLowerMetric.total) {
      return pokemon.stats.fold(0, (sum, stat) => sum + stat.value);
    }

    for (final stat in pokemon.stats) {
      if (stat.name == _metric.statName) {
        return stat.value;
      }
    }

    return 0;
  }

  PokemonPreview? _nextCarryPokemon() => _rightPokemon;

  void _changeSettings({_HigherLowerScope? scope, _HigherLowerMetric? metric}) {
    setState(() {
      _scope = scope ?? _scope;
      _metric = metric ?? _metric;
      _leftPokemon = null;
      _rightPokemon = null;
      _lastGuessWasCorrect = null;
      _selectedPokemonId = null;
      _isRevealed = false;
      _isLoadingNext = false;
      _roundHistory.clear();
      _streak = 0;
      _loadFuture = _loadRound();
    });
  }

  bool _isInScope(PokemonPreview pokemon) {
    return switch (_scope) {
      _HigherLowerScope.classic =>
        (pokemon.generation ?? _generationFromId(pokemon.id)) <= 2,
      _HigherLowerScope.full => true,
      _HigherLowerScope.noLegendaries =>
        !pokemon.isLegendary && !pokemon.isMythical,
    };
  }

  int _generationFromId(int id) {
    if (id <= 151) return 1;
    if (id <= 251) return 2;
    if (id <= 386) return 3;
    if (id <= 493) return 4;
    if (id <= 649) return 5;
    if (id <= 721) return 6;
    if (id <= 809) return 7;
    if (id <= 905) return 8;
    return 9;
  }

  String _formatDateKey(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }
}

enum _HigherLowerScope {
  classic('Gen 1-2'),
  full('Todos'),
  noLegendaries('Sin L/M');

  const _HigherLowerScope(this.label);

  final String label;
}

enum _HigherLowerMetric {
  total('BST', null),
  hp('HP', 'HP'),
  attack('Ataque', 'Ataque'),
  defense('Defensa', 'Defensa'),
  specialAttack('At. esp.', 'Ataque esp.'),
  specialDefense('Def. esp.', 'Defensa esp.'),
  speed('Velocidad', 'Velocidad');

  const _HigherLowerMetric(this.label, this.statName);

  final String label;
  final String? statName;
}

class _HigherLowerRound {
  const _HigherLowerRound({
    required this.left,
    required this.right,
    required this.selected,
    required this.winner,
    required this.wasCorrect,
  });

  final PokemonPreview left;
  final PokemonPreview right;
  final PokemonPreview selected;
  final PokemonPreview winner;
  final bool wasCorrect;
}

class _HigherLowerSettings extends StatelessWidget {
  const _HigherLowerSettings({
    required this.scope,
    required this.metric,
    required this.onScopeChanged,
    required this.onMetricChanged,
  });

  final _HigherLowerScope scope;
  final _HigherLowerMetric metric;
  final ValueChanged<_HigherLowerScope> onScopeChanged;
  final ValueChanged<_HigherLowerMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_HigherLowerScope>(
          segments: [
            for (final value in _HigherLowerScope.values)
              ButtonSegment(value: value, label: Text(value.label)),
          ],
          selected: {scope},
          onSelectionChanged: (selection) {
            onScopeChanged(selection.first);
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<_HigherLowerMetric>(
          initialValue: metric,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Comparar por',
          ),
          items: [
            for (final value in _HigherLowerMetric.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              onMetricChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _HigherLowerCard extends StatelessWidget {
  const _HigherLowerCard({
    required this.pokemon,
    required this.isRevealed,
    required this.total,
    required this.isBestMatch,
    required this.isSelected,
    required this.onChoose,
  });

  final PokemonPreview pokemon;
  final bool isRevealed;
  final int total;
  final bool isBestMatch;
  final bool isSelected;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlightColor = isBestMatch
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final borderColor = !isRevealed
        ? colorScheme.outlineVariant
        : isBestMatch
        ? const Color(0xFF2E7D32)
        : isSelected
        ? const Color(0xFFC62828)
        : colorScheme.outlineVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isRevealed ? null : onChoose,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isRevealed
                ? highlightColor.withValues(alpha: isBestMatch ? 0.10 : 0.05)
                : null,
            border: Border.all(color: borderColor, width: isRevealed ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              if (isRevealed && (isBestMatch || isSelected))
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    isBestMatch ? Icons.check_circle : Icons.cancel,
                    color: highlightColor,
                    size: 28,
                  ),
                ),
              Column(
                children: [
                  SizedBox(
                    height: 120,
                    child: pokemon.imageUrl == null
                        ? const Icon(Icons.catching_pokemon, size: 48)
                        : Image.network(
                            pokemon.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.catching_pokemon,
                                size: 48,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pokemon.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Container(
                      key: ValueKey('$isRevealed-${pokemon.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isRevealed
                            ? highlightColor.withValues(alpha: 0.14)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isRevealed ? '$total BST' : '??? BST',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.isCorrect});

  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 8),
          Text(
            isCorrect ? 'Correcto' : 'Incorrecto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HigherLowerHistory extends StatelessWidget {
  const _HigherLowerHistory({required this.rounds});

  final List<_HigherLowerRound> rounds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historial', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rounds.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return _HistoryTile(round: rounds[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.round});

  final _HigherLowerRound round;

  @override
  Widget build(BuildContext context) {
    final color = round.wasCorrect
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Container(
      width: 210,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                round.wasCorrect ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Ganador: ${round.winner.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${round.left.name} vs ${round.right.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Elegiste: ${round.selected.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
