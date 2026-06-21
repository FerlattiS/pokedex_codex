import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import '../services/pokedle_progress_repository.dart';
import '../services/pokemon_repository.dart';

class PokedlePage extends StatefulWidget {
  const PokedlePage({
    super.key,
    required this.pokemonRepository,
    required this.progressRepository,
    this.date,
  });

  final PokemonRepository pokemonRepository;
  final PokedleProgressRepository progressRepository;
  final DateTime? date;

  @override
  State<PokedlePage> createState() => _PokedlePageState();
}

class _PokedlePageState extends State<PokedlePage> {
  late final DateTime _date = widget.date ?? DateTime.now();
  late final String _dateKey = _formatDateKey(_date);
  late Future<void> _loadFuture;
  final TextEditingController _guessController = TextEditingController();
  List<PokemonPreview> _catalog = [];
  List<PokemonPreview> _guesses = [];
  PokemonPreview? _target;
  PokemonPreview? _selectedPokemon;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadGame();
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _loadGame() async {
    final catalog = await widget.pokemonRepository.fetchPokemonCatalog();
    if (catalog.isEmpty) {
      throw Exception('Catalogo vacio');
    }

    final targetPreview = catalog[_dailyIndex(catalog.length, _date)];
    final guessIds = await widget.progressRepository.readGuessIds(_dateKey);
    final target = await widget.pokemonRepository.fetchPokemonDetail(
      targetPreview.id,
    );
    final guesses = <PokemonPreview>[];

    for (final id in guessIds) {
      try {
        guesses.add(await widget.pokemonRepository.fetchPokemonDetail(id));
      } catch (_) {
        // Ignore stale guesses that cannot be loaded anymore.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _catalog = catalog;
      _target = target;
      _guesses = guesses;
    });
  }

  Future<void> _submitGuess() async {
    final selectedPokemon = _selectedPokemon;
    if (selectedPokemon == null || _isSubmitting) {
      return;
    }

    if (_guesses.any((guess) => guess.id == selectedPokemon.id)) {
      _guessController.clear();
      setState(() {
        _selectedPokemon = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final detail = await widget.pokemonRepository.fetchPokemonDetail(
        selectedPokemon.id,
      );
      final nextGuesses = [..._guesses, detail];
      await widget.progressRepository.writeGuessIds(
        _dateKey,
        nextGuesses.map((pokemon) => pokemon.id).toList(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _guesses = nextGuesses;
        _selectedPokemon = null;
        _guessController.clear();
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  bool get _hasWon {
    final target = _target;
    return target != null && _guesses.any((guess) => guess.id == target.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || _target == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo cargar POKEDLE PRO'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loadFuture = _loadGame();
                    });
                  },
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
              'POKEDLE PRO',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _hasWon
                  ? 'Correcto: ${_target!.name}'
                  : 'Adivina el Pokemon diario',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _GuessInput(
              catalog: _catalog,
              controller: _guessController,
              enabled: !_hasWon && !_isSubmitting,
              onSelected: (pokemon) {
                setState(() {
                  _selectedPokemon = pokemon;
                });
              },
              onSubmit: _submitGuess,
            ),
            const SizedBox(height: 16),
            if (_isSubmitting) const LinearProgressIndicator(),
            if (_guesses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Todavia no hay intentos')),
              )
            else
              for (final guess in _guesses.reversed)
                _GuessCard(guess: guess, target: _target!),
          ],
        );
      },
    );
  }

  int _dailyIndex(int length, DateTime date) {
    final seed = date.year * 1000 + date.month * 40 + date.day + 73;
    return seed % length;
  }

  String _formatDateKey(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }
}

class _GuessInput extends StatelessWidget {
  const _GuessInput({
    required this.catalog,
    required this.controller,
    required this.enabled,
    required this.onSelected,
    required this.onSubmit,
  });

  final List<PokemonPreview> catalog;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<PokemonPreview> onSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Autocomplete<PokemonPreview>(
            displayStringForOption: (pokemon) => pokemon.name,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) {
                return const Iterable<PokemonPreview>.empty();
              }

              return catalog
                  .where((pokemon) {
                    return pokemon.name.toLowerCase().contains(query) ||
                        pokemon.id.toString().padLeft(3, '0').contains(query);
                  })
                  .take(12);
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onSubmitted) {
                  if (controller.text != textEditingController.text) {
                    textEditingController.text = controller.text;
                  }

                  return TextField(
                    key: const ValueKey('pokedleGuessField'),
                    enabled: enabled,
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ingresar Pokemon',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => onSubmit(),
                  );
                },
            onSelected: (pokemon) {
              controller.text = pokemon.name;
              onSelected(pokemon);
            },
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: enabled ? onSubmit : null,
          child: const Text('Probar'),
        ),
      ],
    );
  }
}

class _GuessCard extends StatelessWidget {
  const _GuessCard({required this.guess, required this.target});

  final PokemonPreview guess;
  final PokemonPreview target;

  @override
  Widget build(BuildContext context) {
    final results = _buildResults();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${guess.id.toString().padLeft(3, '0')} ${guess.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final result in results) _ResultChip(result: result),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_PokedleResult> _buildResults() {
    return [
      _compareType('Tipo 1', _typeAt(guess, 0), target.types),
      _compareType('Tipo 2', _typeAt(guess, 1), target.types, position: 1),
      _compareText('Gen', _generation(guess.id), _generation(target.id)),
      _compareText(
        'Etapa',
        guess.evolutionStage.label,
        target.evolutionStage.label,
      ),
      _compareText('Rareza', _rarity(guess), _rarity(target)),
      _compareNumber(
        'Altura',
        _metricValue(guess.height),
        _metricValue(target.height),
        'm',
      ),
      _compareNumber(
        'Peso',
        _metricValue(guess.weight),
        _metricValue(target.weight),
        'kg',
      ),
      _compareText('Stat top', _highestStat(guess), _highestStat(target)),
    ];
  }

  _PokedleResult _compareType(
    String label,
    String guessType,
    List<String> targetTypes, {
    int position = 0,
  }) {
    final targetType = targetTypes.length > position
        ? targetTypes[position]
        : '-';
    if (guessType == targetType) {
      return _PokedleResult(label, guessType, _PokedleStatus.correct);
    }

    if (guessType != '-' && targetTypes.contains(guessType)) {
      return _PokedleResult(label, guessType, _PokedleStatus.partial);
    }

    return _PokedleResult(label, guessType, _PokedleStatus.wrong);
  }

  _PokedleResult _compareText(
    String label,
    String guessValue,
    String targetValue,
  ) {
    return _PokedleResult(
      label,
      guessValue,
      guessValue == targetValue ? _PokedleStatus.correct : _PokedleStatus.wrong,
    );
  }

  _PokedleResult _compareNumber(
    String label,
    double? guessValue,
    double? targetValue,
    String unit,
  ) {
    if (guessValue == null || targetValue == null) {
      return _PokedleResult(label, '-', _PokedleStatus.wrong);
    }

    if (guessValue == targetValue) {
      return _PokedleResult(
        label,
        '${guessValue.toStringAsFixed(1)} $unit',
        _PokedleStatus.correct,
      );
    }

    final direction = targetValue > guessValue ? '↑' : '↓';
    return _PokedleResult(
      label,
      '${guessValue.toStringAsFixed(1)} $unit $direction',
      _PokedleStatus.wrong,
    );
  }

  String _typeAt(PokemonPreview pokemon, int index) {
    return pokemon.types.length > index ? pokemon.types[index] : '-';
  }

  String _generation(int id) {
    if (id <= 151) return 'Gen 1';
    if (id <= 251) return 'Gen 2';
    if (id <= 386) return 'Gen 3';
    if (id <= 493) return 'Gen 4';
    if (id <= 649) return 'Gen 5';
    if (id <= 721) return 'Gen 6';
    if (id <= 809) return 'Gen 7';
    if (id <= 905) return 'Gen 8';
    return 'Gen 9';
  }

  String _rarity(PokemonPreview pokemon) {
    if (pokemon.isMythical) {
      return 'Mitico';
    }

    if (pokemon.isLegendary) {
      return 'Legendario';
    }

    return 'Normal';
  }

  double? _metricValue(String value) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(value);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(0)!);
  }

  String _highestStat(PokemonPreview pokemon) {
    if (pokemon.stats.isEmpty) {
      return '-';
    }

    final stats = [...pokemon.stats]
      ..sort((first, second) => second.value.compareTo(first.value));

    return stats.first.name;
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.result});

  final _PokedleResult result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.status) {
      _PokedleStatus.correct => const Color(0xFF2E7D32),
      _PokedleStatus.partial => const Color(0xFFF9A825),
      _PokedleStatus.wrong => const Color(0xFFC62828),
    };

    return Container(
      width: 118,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(result.label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            result.value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PokedleResult {
  const _PokedleResult(this.label, this.value, this.status);

  final String label;
  final String value;
  final _PokedleStatus status;
}

enum _PokedleStatus { correct, partial, wrong }
