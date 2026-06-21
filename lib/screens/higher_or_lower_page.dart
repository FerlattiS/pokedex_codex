import 'dart:math';

import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import '../services/pokemon_repository.dart';

class HigherOrLowerPage extends StatefulWidget {
  const HigherOrLowerPage({super.key, required this.pokemonRepository});

  final PokemonRepository pokemonRepository;

  @override
  State<HigherOrLowerPage> createState() => _HigherOrLowerPageState();
}

class _HigherOrLowerPageState extends State<HigherOrLowerPage> {
  final Random _random = Random();
  late Future<void> _loadFuture = _loadRound();
  List<PokemonPreview> _catalog = [];
  PokemonPreview? _leftPokemon;
  PokemonPreview? _rightPokemon;
  bool? _lastGuessWasCorrect;
  var _streak = 0;
  var _bestStreak = 0;
  var _isRevealed = false;
  var _isLoadingNext = false;
  int? _selectedPokemonId;

  Future<void> _loadRound({PokemonPreview? carryPokemon}) async {
    final catalog = _catalog.isEmpty
        ? await widget.pokemonRepository.fetchPokemonCatalog()
        : _catalog;
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
      _catalog = catalog;
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

    setState(() {
      _isRevealed = true;
      _lastGuessWasCorrect = isCorrect;
      _selectedPokemonId = selected.id;
      _streak = isCorrect ? _streak + 1 : 0;
      if (_streak > _bestStreak) {
        _bestStreak = _streak;
      }
    });
  }

  Future<void> _nextRound() async {
    if (_isLoadingNext) {
      return;
    }

    final carryPokemon = _isRevealed ? _roundWinner() : null;

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
    return pokemon.stats.fold(0, (sum, stat) => sum + stat.value);
  }

  PokemonPreview? _roundWinner() {
    final left = _leftPokemon;
    final right = _rightPokemon;
    if (left == null || right == null) {
      return null;
    }

    return _battleStatTotal(left) >= _battleStatTotal(right) ? left : right;
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
