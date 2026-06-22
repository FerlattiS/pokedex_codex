import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pokemon_preview.dart';
import '../services/game_results_repository.dart';
import '../services/pokemon_questions_progress_repository.dart';
import '../services/pokemon_repository.dart';

class PokemonQuestionsPage extends StatefulWidget {
  const PokemonQuestionsPage({
    super.key,
    required this.pokemonRepository,
    required this.progressRepository,
    required this.gameResultsRepository,
    this.date,
  });

  final PokemonRepository pokemonRepository;
  final PokemonQuestionsProgressRepository progressRepository;
  final GameResultsRepository gameResultsRepository;
  final DateTime? date;

  @override
  State<PokemonQuestionsPage> createState() => _PokemonQuestionsPageState();
}

class _PokemonQuestionsPageState extends State<PokemonQuestionsPage> {
  static const _maxQuestions = 15;
  static const _maxGuesses = 3;

  late final DateTime _date = widget.date ?? DateTime.now();
  late final String _dateKey = _formatDateKey(_date);
  late final String _sessionKey = _dateKey;
  late Future<void> _loadFuture = _loadGame();
  final TextEditingController _guessController = TextEditingController();
  List<PokemonPreview> _catalog = [];
  List<_AskedQuestion> _askedQuestions = [];
  List<PokemonPreview> _guesses = [];
  PokemonPreview? _target;
  PokemonPreview? _selectedPokemon;
  String? _selectedQuestionId;
  var _hasWon = false;
  var _resultWasSaved = false;

  bool get _hasLost => !_hasWon && _guesses.length >= _maxGuesses;

  bool get _isGameOver => _hasWon || _hasLost;

  int get _remainingQuestions => _maxQuestions - _askedQuestions.length;

  int get _remainingGuesses => _maxGuesses - _guesses.length;

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
    final target = await widget.pokemonRepository.fetchPokemonDetail(
      targetPreview.id,
    );
    final savedState = await widget.progressRepository.readState(_sessionKey);
    final questionById = {
      for (final question in _buildQuestions()) question.id: question,
    };
    final askedQuestions = <_AskedQuestion>[];
    final guesses = <PokemonPreview>[];

    for (final questionId in savedState?.askedQuestionIds ?? <String>[]) {
      final question = questionById[questionId];
      if (question != null) {
        askedQuestions.add(
          _AskedQuestion(question: question, answer: question.answer(target)),
        );
      }
    }

    for (final id in savedState?.guessIds ?? <int>[]) {
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
      _askedQuestions = askedQuestions;
      _guesses = guesses;
      _hasWon = guesses.any((guess) => guess.id == target.id);
      _resultWasSaved = _isGameOver;
      _selectedQuestionId = _availableQuestions(askedQuestions).firstOrNull?.id;
    });
  }

  Future<void> _askQuestion() async {
    final target = _target;
    final question = _selectedQuestion;
    if (target == null ||
        question == null ||
        _isGameOver ||
        _remainingQuestions <= 0) {
      return;
    }

    final nextAsked = [
      _AskedQuestion(question: question, answer: question.answer(target)),
      ..._askedQuestions,
    ];

    setState(() {
      _askedQuestions = nextAsked;
      _selectedQuestionId = _availableQuestions(nextAsked).firstOrNull?.id;
    });

    await _persistState(askedQuestions: nextAsked);
  }

  Future<void> _submitGuess() async {
    final selectedPokemon = _selectedPokemon;
    final target = _target;
    if (selectedPokemon == null || target == null || _isGameOver) {
      return;
    }

    if (_guesses.any((guess) => guess.id == selectedPokemon.id)) {
      _guessController.clear();
      setState(() {
        _selectedPokemon = null;
      });
      return;
    }

    final nextGuesses = [selectedPokemon, ..._guesses];
    final hasWon = selectedPokemon.id == target.id;

    setState(() {
      _guesses = nextGuesses;
      _hasWon = hasWon;
      _selectedPokemon = null;
      _guessController.clear();
    });

    await _persistState(guesses: nextGuesses);
    if (hasWon || nextGuesses.length >= _maxGuesses) {
      await _writeGameResult(guesses: nextGuesses, won: hasWon);
    }
  }

  Future<void> _persistState({
    List<_AskedQuestion>? askedQuestions,
    List<PokemonPreview>? guesses,
  }) async {
    await widget.progressRepository.writeState(
      PokemonQuestionsGameState(
        sessionKey: _sessionKey,
        askedQuestionIds: (askedQuestions ?? _askedQuestions)
            .map((question) => question.question.id)
            .toList(),
        guessIds: (guesses ?? _guesses).map((pokemon) => pokemon.id).toList(),
      ),
    );
  }

  Future<void> _writeGameResult({
    required List<PokemonPreview> guesses,
    required bool won,
  }) async {
    if (_resultWasSaved) {
      return;
    }

    final target = _target;
    await widget.gameResultsRepository.writeResult(
      GameResult(
        id: 'pokemon_questions.$_sessionKey',
        gameId: 'pokemon_questions',
        dateKey: _dateKey,
        won: won,
        score: won ? _remainingQuestions : 0,
        attempts: guesses.length,
        streak: won ? 1 : 0,
        completedAt: DateTime.now(),
        metadata: {
          if (target != null) 'targetId': '${target.id}',
          'questionsUsed': '${_askedQuestions.length}',
        },
      ),
    );

    _resultWasSaved = true;
  }

  Future<void> _copyShareResult() async {
    await Clipboard.setData(ClipboardData(text: _buildShareText()));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resultado copiado al portapapeles')),
    );
  }

  String _buildShareText() {
    final result = _hasWon
        ? 'Gane'
        : _hasLost
        ? 'Perdi'
        : 'En juego';

    return [
      '15 Preguntas $_dateKey',
      '$result - preguntas ${_askedQuestions.length}/$_maxQuestions - intentos ${_guesses.length}/$_maxGuesses',
      for (final question in _askedQuestions.reversed)
        '${question.answer ? 'Si' : 'No'} - ${question.question.label}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            _target == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo cargar 15 Preguntas'),
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

        final target = _target!;
        final questions = _availableQuestions();
        final selectedQuestion = _selectedQuestion;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '15 Preguntas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _isGameOver
                  ? _hasWon
                        ? 'Correcto: ${target.name}'
                        : 'Sin intentos: era ${target.name}'
                  : 'Pregunta hasta 15 veces y tenes 3 intentos para adivinar',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _MysteryPokemon(
              target: target,
              isRevealed: _isGameOver,
              dateKey: _dateKey,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _CounterChip(
                  icon: Icons.help_outline,
                  label: 'Preguntas',
                  value: '$_remainingQuestions/$_maxQuestions',
                ),
                _CounterChip(
                  icon: Icons.catching_pokemon,
                  label: 'Intentos',
                  value: '$_remainingGuesses/$_maxGuesses',
                ),
              ],
            ),
            if (_askedQuestions.isNotEmpty || _guesses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _copyShareResult,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Copiar resultado'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedQuestion?.id,
              items: [
                for (final question in questions)
                  DropdownMenuItem(
                    value: question.id,
                    child: Text(
                      '${question.category}: ${question.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Pregunta',
              ),
              onChanged: _isGameOver || _remainingQuestions <= 0
                  ? null
                  : (value) {
                      setState(() {
                        _selectedQuestionId = value;
                      });
                    },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed:
                  selectedQuestion == null ||
                      _isGameOver ||
                      _remainingQuestions <= 0
                  ? null
                  : _askQuestion,
              icon: const Icon(Icons.question_answer_outlined),
              label: const Text('Preguntar'),
            ),
            const SizedBox(height: 16),
            _PokemonGuessInput(
              catalog: _catalog,
              controller: _guessController,
              enabled: !_isGameOver,
              onSelected: (pokemon) {
                setState(() {
                  _selectedPokemon = pokemon;
                });
              },
              onSubmit: _submitGuess,
            ),
            const SizedBox(height: 16),
            if (_askedQuestions.isNotEmpty)
              _AskedQuestionsList(questions: _askedQuestions),
            if (_guesses.isNotEmpty) ...[
              const SizedBox(height: 16),
              _GuessList(guesses: _guesses, target: target),
            ],
          ],
        );
      },
    );
  }

  _QuestionDefinition? get _selectedQuestion {
    for (final question in _availableQuestions()) {
      if (question.id == _selectedQuestionId) {
        return question;
      }
    }

    return null;
  }

  List<_QuestionDefinition> _availableQuestions([
    List<_AskedQuestion>? askedQuestions,
  ]) {
    final askedIds = (askedQuestions ?? _askedQuestions)
        .map((question) => question.question.id)
        .toSet();

    return _buildQuestions().where((question) {
      return !askedIds.contains(question.id);
    }).toList();
  }

  List<_QuestionDefinition> _buildQuestions() {
    return [
      for (var generation = 1; generation <= 9; generation++)
        _QuestionDefinition(
          id: 'generation-$generation',
          category: 'Generacion',
          label: 'Pertenece a la generacion $generation?',
          answer: (pokemon) =>
              (pokemon.generation ?? _generationFromId(pokemon.id)) ==
              generation,
        ),
      for (var generation = 2; generation <= 9; generation++)
        _QuestionDefinition(
          id: 'before-generation-$generation',
          category: 'Generacion',
          label: 'Salio antes de la generacion $generation?',
          answer: (pokemon) =>
              (pokemon.generation ?? _generationFromId(pokemon.id)) <
              generation,
        ),
      for (var generation = 1; generation <= 8; generation++)
        _QuestionDefinition(
          id: 'after-generation-$generation',
          category: 'Generacion',
          label: 'Salio despues de la generacion $generation?',
          answer: (pokemon) =>
              (pokemon.generation ?? _generationFromId(pokemon.id)) >
              generation,
        ),
      for (final type in _pokemonTypes)
        _QuestionDefinition(
          id: 'type-$type',
          category: 'Tipo',
          label: 'Es de tipo $type?',
          answer: (pokemon) => pokemon.types.contains(type),
        ),
      for (final color in _pokemonColors)
        _QuestionDefinition(
          id: 'color-$color',
          category: 'Color',
          label: 'Su color principal es $color?',
          answer: (pokemon) => pokemon.speciesColor == color,
        ),
      _QuestionDefinition(
        id: 'dual-type',
        category: 'Tipos',
        label: 'Tiene doble tipo?',
        answer: (pokemon) => pokemon.types.length >= 2,
      ),
      _QuestionDefinition(
        id: 'mono-type',
        category: 'Tipos',
        label: 'Es monotipo?',
        answer: (pokemon) => pokemon.types.length == 1,
      ),
      _QuestionDefinition(
        id: 'legendary',
        category: 'Rareza',
        label: 'Es legendario?',
        answer: (pokemon) => pokemon.isLegendary,
      ),
      _QuestionDefinition(
        id: 'mythical',
        category: 'Rareza',
        label: 'Es mitico?',
        answer: (pokemon) => pokemon.isMythical,
      ),
      _QuestionDefinition(
        id: 'item-evolution',
        category: 'Evolucion',
        label: 'Evoluciona por objeto?',
        answer: (pokemon) => pokemon.evolvesByItem,
      ),
      _QuestionDefinition(
        id: 'has-evolution',
        category: 'Evolucion',
        label: 'Tiene linea evolutiva?',
        answer: (pokemon) => pokemon.evolutionLine.length > 1,
      ),
      _QuestionDefinition(
        id: 'final-stage',
        category: 'Evolucion',
        label: 'Es etapa final?',
        answer: (pokemon) =>
            pokemon.evolutionStage == PokemonEvolutionStage.finalStage ||
            pokemon.evolutionStage == PokemonEvolutionStage.standalone,
      ),
      _QuestionDefinition(
        id: 'alternative-form',
        category: 'Forma',
        label: 'Es una forma alternativa?',
        answer: (pokemon) => pokemon.formLabel != 'Normal',
      ),
      for (var stage = 1; stage <= 3; stage++)
        _QuestionDefinition(
          id: 'stage-$stage',
          category: 'Evolucion',
          label: 'Es etapa evolutiva $stage?',
          answer: (pokemon) => _stageNumber(pokemon) == stage,
        ),
      _QuestionDefinition(
        id: 'height-small',
        category: 'Altura',
        label: 'Mide menos de 1 metro?',
        answer: (pokemon) => (_metricValue(pokemon.height) ?? 999) < 1,
      ),
      _QuestionDefinition(
        id: 'height-large',
        category: 'Altura',
        label: 'Mide 2 metros o mas?',
        answer: (pokemon) => (_metricValue(pokemon.height) ?? 0) >= 2,
      ),
      _QuestionDefinition(
        id: 'weight-light',
        category: 'Peso',
        label: 'Pesa menos de 20 kg?',
        answer: (pokemon) => (_metricValue(pokemon.weight) ?? 999) < 20,
      ),
      _QuestionDefinition(
        id: 'weight-heavy',
        category: 'Peso',
        label: 'Pesa 100 kg o mas?',
        answer: (pokemon) => (_metricValue(pokemon.weight) ?? 0) >= 100,
      ),
      for (final stat in _questionStats)
        _QuestionDefinition(
          id: 'top-stat-$stat',
          category: 'Stats',
          label: 'Su stat mas alto es $stat?',
          answer: (pokemon) => _highestStat(pokemon) == stat,
        ),
      for (final move in _questionMoves)
        _QuestionDefinition(
          id: 'move-${move.apiName}',
          category: 'Movimiento',
          label: 'Puede aprender ${move.name}?',
          answer: (pokemon) => pokemon.moves.any(
            (pokemonMove) => pokemonMove.apiName == move.apiName,
          ),
        ),
      for (final ability in _questionAbilities)
        _QuestionDefinition(
          id: 'ability-${ability.apiName}',
          category: 'Habilidad',
          label: 'Puede tener ${ability.name}?',
          answer: (pokemon) => pokemon.abilities.any(
            (pokemonAbility) => pokemonAbility.apiName == ability.apiName,
          ),
        ),
    ];
  }

  int _dailyIndex(int length, DateTime date) {
    final seed = date.year * 1000 + date.month * 40 + date.day + 191;
    return seed % length;
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

  int? _stageNumber(PokemonPreview pokemon) {
    return switch (pokemon.evolutionStage) {
      PokemonEvolutionStage.standalone || PokemonEvolutionStage.base => 1,
      PokemonEvolutionStage.middle => 2,
      PokemonEvolutionStage.finalStage =>
        pokemon.evolutionLine.length <= 2 ? 2 : 3,
      PokemonEvolutionStage.unknown => null,
    };
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

  String _formatDateKey(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }
}

class _MysteryPokemon extends StatelessWidget {
  const _MysteryPokemon({
    required this.target,
    required this.isRevealed,
    required this.dateKey,
  });

  final PokemonPreview target;
  final bool isRevealed;
  final String dateKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 132,
              child: isRevealed && target.imageUrl != null
                  ? Image.network(
                      target.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.catching_pokemon, size: 56);
                      },
                    )
                  : const Icon(Icons.question_mark, size: 72),
            ),
            const SizedBox(height: 8),
            Text(
              isRevealed ? target.name : 'Pokemon oculto',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(dateKey, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label: $value'));
  }
}

class _PokemonGuessInput extends StatelessWidget {
  const _PokemonGuessInput({
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
                    key: const ValueKey('pokemonQuestionsGuessField'),
                    enabled: enabled,
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Adivinar Pokemon',
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
          child: const Text('Adivinar'),
        ),
      ],
    );
  }
}

class _AskedQuestionsList extends StatelessWidget {
  const _AskedQuestionsList({required this.questions});

  final List<_AskedQuestion> questions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.question_answer_outlined),
            title: Text('Preguntas realizadas'),
          ),
          for (final question in questions) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              title: Text(question.question.label),
              subtitle: Text(question.question.category),
              trailing: Text(
                question.answer ? 'Si' : 'No',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: question.answer
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuessList extends StatelessWidget {
  const _GuessList({required this.guesses, required this.target});

  final List<PokemonPreview> guesses;
  final PokemonPreview target;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.catching_pokemon),
            title: Text('Intentos de respuesta'),
          ),
          for (final guess in guesses) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: Icon(
                guess.id == target.id ? Icons.check_circle : Icons.cancel,
                color: guess.id == target.id
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
              title: Text(guess.name),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionDefinition {
  const _QuestionDefinition({
    required this.id,
    required this.category,
    required this.label,
    required this.answer,
  });

  final String id;
  final String category;
  final String label;
  final bool Function(PokemonPreview pokemon) answer;
}

class _AskedQuestion {
  const _AskedQuestion({required this.question, required this.answer});

  final _QuestionDefinition question;
  final bool answer;
}

const _pokemonTypes = [
  'Normal',
  'Fuego',
  'Agua',
  'Planta',
  'Electrico',
  'Hielo',
  'Lucha',
  'Veneno',
  'Tierra',
  'Volador',
  'Psiquico',
  'Bicho',
  'Roca',
  'Fantasma',
  'Dragon',
  'Siniestro',
  'Acero',
  'Hada',
];

const _pokemonColors = [
  'Negro',
  'Azul',
  'Marron',
  'Gris',
  'Verde',
  'Rosa',
  'Violeta',
  'Rojo',
  'Blanco',
  'Amarillo',
];

const _questionStats = [
  'HP',
  'Ataque',
  'Defensa',
  'Ataque esp.',
  'Defensa esp.',
  'Velocidad',
];

const _questionMoves = [
  _QuestionMove(name: 'Placaje', apiName: 'tackle'),
  _QuestionMove(name: 'Aranazo', apiName: 'scratch'),
  _QuestionMove(name: 'Impactrueno', apiName: 'thunder-shock'),
];

const _questionAbilities = [
  _QuestionAbility(name: 'Espesura', apiName: 'overgrow'),
  _QuestionAbility(name: 'Mar llamas', apiName: 'blaze'),
];

class _QuestionMove {
  const _QuestionMove({required this.name, required this.apiName});

  final String name;
  final String apiName;
}

class _QuestionAbility {
  const _QuestionAbility({required this.name, required this.apiName});

  final String name;
  final String apiName;
}
