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
  PokedleSettings _settings = const PokedleSettings.defaults();
  PokedleDailyResult? _result;
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
    final settings = await widget.progressRepository.readSettings();
    final fullCatalog = await widget.pokemonRepository.fetchPokemonCatalog();
    final catalog = fullCatalog.where((pokemon) {
      return _isInScope(pokemon, settings.dexScope);
    }).toList();
    if (catalog.isEmpty) {
      throw Exception('Catalogo vacio');
    }

    final sessionKey = _sessionKey(settings);
    final targetPreview = catalog[_dailyIndex(catalog.length, _date, settings)];
    final guessIds = await widget.progressRepository.readGuessIds(sessionKey);
    final result = await widget.progressRepository.readResult(sessionKey);
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
      _settings = settings;
      _result = result;
      _target = target;
      _guesses = guesses;
    });
  }

  Future<void> _submitGuess() async {
    final selectedPokemon = _selectedPokemon;
    if (selectedPokemon == null || _isSubmitting || _isGameOver) {
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
      final wonWithGuess = detail.id == _target?.id;
      final lostWithGuess =
          !wonWithGuess &&
          _settings.attemptMode.maxAttempts != null &&
          nextGuesses.length >= _settings.attemptMode.maxAttempts!;
      final sessionKey = _sessionKey(_settings);
      final result = wonWithGuess || lostWithGuess
          ? PokedleDailyResult(
              sessionKey: sessionKey,
              dateKey: _dateKey,
              dexScope: _settings.dexScope,
              attemptMode: _settings.attemptMode,
              targetId: _target!.id,
              won: wonWithGuess,
              attempts: nextGuesses.length,
              completedAt: DateTime.now(),
            )
          : null;

      await widget.progressRepository.writeGuessIds(
        sessionKey,
        nextGuesses.map((pokemon) => pokemon.id).toList(),
      );
      if (result != null) {
        await widget.progressRepository.writeResult(result);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _guesses = nextGuesses;
        _result = result;
        _selectedPokemon = null;
        _guessController.clear();
        _isSubmitting = false;
      });

      if (wonWithGuess) {
        await _showWinDialog(detail, nextGuesses.length);
      } else if (lostWithGuess) {
        await _showLoseDialog(_target!);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _changeSettings(PokedleSettings settings) async {
    await widget.progressRepository.writeSettings(settings);
    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _selectedPokemon = null;
      _guessController.clear();
      _loadFuture = _loadGame();
    });
  }

  Future<void> _showWinDialog(PokemonPreview pokemon, int attempts) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.emoji_events_outlined),
          title: const Text('Ganaste POKEDLE PRO'),
          content: Text(
            'Adivinaste el Pokemon diario: ${pokemon.name} en $attempts '
            'intentos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLoseDialog(PokemonPreview pokemon) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.sentiment_dissatisfied_outlined),
          title: const Text('Sin intentos'),
          content: Text('Se acabaron los 10 intentos. Era ${pokemon.name}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  bool get _hasWon {
    final target = _target;
    return _result?.won == true ||
        (target != null && _guesses.any((guess) => guess.id == target.id));
  }

  bool get _hasLost => _result != null && !_result!.won;

  bool get _isGameOver => _hasWon || _hasLost;

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
                  : _hasLost
                  ? 'Sin intentos: era ${_target!.name}'
                  : 'Adivina el Pokemon diario',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _PokedleSettingsPanel(
              settings: _settings,
              onChanged: _changeSettings,
            ),
            const SizedBox(height: 16),
            _AttemptSummary(
              guesses: _guesses.length,
              attemptMode: _settings.attemptMode,
            ),
            const SizedBox(height: 12),
            _GuessInput(
              catalog: _catalog,
              controller: _guessController,
              enabled: !_isGameOver && !_isSubmitting,
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

  int _dailyIndex(int length, DateTime date, PokedleSettings settings) {
    final seed =
        date.year * 1000 +
        date.month * 40 +
        date.day +
        settings.dexScope.index * 97 +
        settings.attemptMode.index * 31 +
        73;
    return seed % length;
  }

  bool _isInScope(PokemonPreview pokemon, PokedleDexScope scope) {
    return switch (scope) {
      PokedleDexScope.classic =>
        (pokemon.generation ?? _generationFromId(pokemon.id)) <= 2,
      PokedleDexScope.full => true,
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

  String _sessionKey(PokedleSettings settings) {
    return '$_dateKey.${settings.dexScope.name}.${settings.attemptMode.name}';
  }

  String _formatDateKey(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }
}

class _PokedleSettingsPanel extends StatelessWidget {
  const _PokedleSettingsPanel({
    required this.settings,
    required this.onChanged,
  });

  final PokedleSettings settings;
  final ValueChanged<PokedleSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<PokedleDexScope>(
          segments: [
            for (final scope in PokedleDexScope.values)
              ButtonSegment<PokedleDexScope>(
                value: scope,
                label: Text(scope.label),
              ),
          ],
          selected: {settings.dexScope},
          onSelectionChanged: (selection) {
            onChanged(
              PokedleSettings(
                dexScope: selection.first,
                attemptMode: settings.attemptMode,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        SegmentedButton<PokedleAttemptMode>(
          segments: [
            for (final mode in PokedleAttemptMode.values)
              ButtonSegment<PokedleAttemptMode>(
                value: mode,
                icon: Icon(
                  mode == PokedleAttemptMode.hard
                      ? Icons.timer_outlined
                      : Icons.all_inclusive,
                ),
                label: Text(mode.label),
              ),
          ],
          selected: {settings.attemptMode},
          onSelectionChanged: (selection) {
            onChanged(
              PokedleSettings(
                dexScope: settings.dexScope,
                attemptMode: selection.first,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AttemptSummary extends StatelessWidget {
  const _AttemptSummary({required this.guesses, required this.attemptMode});

  final int guesses;
  final PokedleAttemptMode attemptMode;

  @override
  Widget build(BuildContext context) {
    final maxAttempts = attemptMode.maxAttempts;
    final text = maxAttempts == null
        ? 'Intentos: $guesses'
        : 'Intentos: $guesses/$maxAttempts';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          maxAttempts == null ? Icons.all_inclusive : Icons.timer_outlined,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
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
            Row(
              children: [
                _GuessImage(pokemon: guess),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    guess.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
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
      _compareNumber(
        'Gen',
        guess.generation,
        target.generation,
        (value) => 'Gen ${value.toInt()}',
      ),
      _compareNumber(
        'Etapa',
        _stageNumber(guess),
        _stageNumber(target),
        (value) => '${value.toInt()}',
      ),
      _compareText('Rareza', _rarity(guess), _rarity(target)),
      _compareNumber(
        'Altura',
        _metricValue(guess.height),
        _metricValue(target.height),
        (value) => '${value.toStringAsFixed(1)} m',
      ),
      _compareNumber(
        'Peso',
        _metricValue(guess.weight),
        _metricValue(target.weight),
        (value) => '${value.toStringAsFixed(1)} kg',
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
    num? guessValue,
    num? targetValue,
    String Function(num value) format,
  ) {
    if (guessValue == null || targetValue == null) {
      return _PokedleResult(label, '-', _PokedleStatus.wrong);
    }

    if (guessValue == targetValue) {
      return _PokedleResult(label, format(guessValue), _PokedleStatus.correct);
    }

    return _PokedleResult(
      label,
      format(guessValue),
      _PokedleStatus.wrong,
      direction: targetValue > guessValue
          ? _PokedleDirection.higher
          : _PokedleDirection.lower,
    );
  }

  String _typeAt(PokemonPreview pokemon, int index) {
    return pokemon.types.length > index ? pokemon.types[index] : '-';
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

  int? _stageNumber(PokemonPreview pokemon) {
    final lineStage = _stageNumberFromEvolutionLine(pokemon);
    if (lineStage != null) {
      return lineStage;
    }

    return switch (pokemon.evolutionStage) {
      PokemonEvolutionStage.standalone || PokemonEvolutionStage.base => 1,
      PokemonEvolutionStage.middle => 2,
      PokemonEvolutionStage.finalStage =>
        pokemon.evolutionLine.length <= 2 ? 2 : 3,
      PokemonEvolutionStage.unknown => null,
    };
  }

  int? _stageNumberFromEvolutionLine(PokemonPreview pokemon) {
    if (pokemon.evolutionLine.isEmpty) {
      return null;
    }

    final normalizedName = _normalizeEvolutionName(pokemon.name);
    final baseFormName = _normalizeBaseFormName(pokemon.name);

    for (var index = 0; index < pokemon.evolutionLine.length; index++) {
      final step = pokemon.evolutionLine[index];
      final stepName = _normalizeEvolutionName(step.name);
      if (step.id == pokemon.id ||
          stepName == normalizedName ||
          stepName == baseFormName) {
        return (index + 1).clamp(1, 3);
      }
    }

    return null;
  }

  String _normalizeEvolutionName(String value) {
    return value.toLowerCase().replaceAll(' ', '-');
  }

  String _normalizeBaseFormName(String value) {
    var normalized = _normalizeEvolutionName(value);
    const suffixes = [
      '-mega-x',
      '-mega-y',
      '-bloodmoon',
      '-alola',
      '-galar',
      '-hisui',
      '-paldea',
      '-mega',
      '-gmax',
      '-totem',
    ];

    for (final suffix in suffixes) {
      if (normalized.endsWith(suffix)) {
        normalized = normalized.substring(0, normalized.length - suffix.length);
        break;
      }
    }

    return normalized;
  }
}

class _GuessImage extends StatelessWidget {
  const _GuessImage({required this.pokemon});

  final PokemonPreview pokemon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = pokemon.imageUrl;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? const Icon(Icons.catching_pokemon)
          : Image.network(
              imageUrl,
              key: ValueKey('pokedleGuessImage-${pokemon.id}'),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.catching_pokemon);
              },
            ),
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  result.value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (result.direction != null) ...[
                const SizedBox(width: 2),
                Icon(
                  result.direction == _PokedleDirection.higher
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 14,
                  color: color,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PokedleResult {
  const _PokedleResult(this.label, this.value, this.status, {this.direction});

  final String label;
  final String value;
  final _PokedleStatus status;
  final _PokedleDirection? direction;
}

enum _PokedleStatus { correct, partial, wrong }

enum _PokedleDirection { higher, lower }
