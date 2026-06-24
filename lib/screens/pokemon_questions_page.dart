import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pokemon_preview.dart';
import '../models/pokemon_question_definition.dart';
import '../services/game_results_repository.dart';
import '../services/pokemon_questions_progress_repository.dart';
import '../services/pokemon_repository.dart';
import '../widgets/game_reveal_panel.dart';
import '../widgets/pokemon_type_chips.dart';

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
  final TextEditingController _questionSearchController =
      TextEditingController();
  List<PokemonPreview> _catalog = [];
  List<_AskedQuestion> _askedQuestions = [];
  List<PokemonPreview> _guesses = [];
  PokemonPreview? _target;
  PokemonPreview? _selectedPokemon;
  String? _selectedCategory;
  String? _selectedQuestionId;
  Set<String> _favoriteQuestionIds = {};
  var _hasWon = false;
  var _resultWasSaved = false;

  bool get _hasLost => !_hasWon && _guesses.length >= _maxGuesses;

  bool get _isGameOver => _hasWon || _hasLost;

  int get _remainingQuestions => _maxQuestions - _askedQuestions.length;

  int get _remainingGuesses => _maxGuesses - _guesses.length;

  @override
  void dispose() {
    _guessController.dispose();
    _questionSearchController.dispose();
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
    final preferences = await widget.progressRepository.readPreferences();
    final questionById = {
      for (final question in buildPokemonQuestions()) question.id: question,
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
      _favoriteQuestionIds = preferences.favoriteQuestionIds.toSet();
      _selectAvailableQuestion(
        askedQuestions: askedQuestions,
        preferredCategory: preferences.selectedCategory,
      );
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
      _selectAvailableQuestion(
        askedQuestions: nextAsked,
        preferredCategory: question.category,
      );
    });

    await _persistState(askedQuestions: nextAsked);
    await _writeQuestionPreferences();
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Usar un intento?'),
          content: Text(
            'Vas a responder ${selectedPokemon.name}. Te quedan $_remainingGuesses intentos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
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

  Future<void> _writeQuestionPreferences() async {
    await widget.progressRepository.writePreferences(
      PokemonQuestionsPreferences(
        selectedCategory: _selectedCategory,
        favoriteQuestionIds: _favoriteQuestionIds.toList()..sort(),
      ),
    );
  }

  void _toggleFavoriteQuestion(String questionId) {
    setState(() {
      if (!_favoriteQuestionIds.add(questionId)) {
        _favoriteQuestionIds.remove(questionId);
      }
    });
    _writeQuestionPreferences();
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
        final availableQuestions = _availableQuestions();
        final categories = _availableCategories(availableQuestions);
        final questions = _questionsForCategory(
          availableQuestions,
          _selectedCategory,
        );
        final visibleQuestions = _visibleQuestions(questions);
        final selectedQuestion = visibleQuestions
            .where((question) => question.id == _selectedQuestionId)
            .firstOrNull;

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
              key: const ValueKey('pokemonQuestionsCategoryField'),
              isExpanded: true,
              initialValue: _selectedCategory,
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(
                      '$category (${_questionCountForCategory(availableQuestions, category)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Categoria',
              ),
              onChanged: _isGameOver || _remainingQuestions <= 0
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory = value;
                        _questionSearchController.clear();
                        _selectedQuestionId = _questionsForCategory(
                          availableQuestions,
                          value,
                        ).firstOrNull?.id;
                      });
                      _writeQuestionPreferences();
                    },
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('pokemonQuestionsSearchField'),
              controller: _questionSearchController,
              enabled: !_isGameOver && _remainingQuestions > 0,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Buscar pregunta',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _questionSearchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar busqueda',
                        onPressed: () {
                          setState(() {
                            _questionSearchController.clear();
                            _selectedQuestionId = questions.firstOrNull?.id;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (_) {
                setState(() {
                  _selectedQuestionId = _visibleQuestions(
                    questions,
                  ).firstOrNull?.id;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('pokemonQuestionsQuestionField'),
                    isExpanded: true,
                    initialValue: selectedQuestion?.id,
                    items: [
                      for (final question in visibleQuestions)
                        DropdownMenuItem(
                          value: question.id,
                          child: Row(
                            children: [
                              if (_favoriteQuestionIds.contains(question.id))
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.star, size: 17),
                                ),
                              Expanded(
                                child: Text(
                                  question.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: visibleQuestions.isEmpty
                          ? 'Sin resultados'
                          : 'Pregunta',
                    ),
                    onChanged: _isGameOver || _remainingQuestions <= 0
                        ? null
                        : (value) {
                            setState(() {
                              _selectedQuestionId = value;
                            });
                          },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: selectedQuestion == null
                      ? 'Selecciona una pregunta'
                      : _favoriteQuestionIds.contains(selectedQuestion.id)
                      ? 'Quitar de favoritas'
                      : 'Agregar a favoritas',
                  onPressed: selectedQuestion == null
                      ? null
                      : () => _toggleFavoriteQuestion(selectedQuestion.id),
                  icon: Icon(
                    selectedQuestion != null &&
                            _favoriteQuestionIds.contains(selectedQuestion.id)
                        ? Icons.star
                        : Icons.star_border,
                  ),
                ),
              ],
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

  PokemonQuestionDefinition? get _selectedQuestion {
    for (final question in _questionsForCategory(
      _availableQuestions(),
      _selectedCategory,
    )) {
      if (question.id == _selectedQuestionId) {
        return question;
      }
    }

    return null;
  }

  List<PokemonQuestionDefinition> _availableQuestions([
    List<_AskedQuestion>? askedQuestions,
  ]) {
    final askedIds = (askedQuestions ?? _askedQuestions)
        .map((question) => question.question.id)
        .toSet();

    return buildPokemonQuestions().where((question) {
      return !askedIds.contains(question.id);
    }).toList();
  }

  List<String> _availableCategories(
    List<PokemonQuestionDefinition> availableQuestions,
  ) {
    return availableQuestions
        .map((question) => question.category)
        .toSet()
        .toList();
  }

  List<PokemonQuestionDefinition> _questionsForCategory(
    List<PokemonQuestionDefinition> availableQuestions,
    String? category,
  ) {
    if (category == null) {
      return const [];
    }

    final questions = availableQuestions
        .where((question) => question.category == category)
        .toList();
    return [
      ...questions.where(
        (question) => _favoriteQuestionIds.contains(question.id),
      ),
      ...questions.where(
        (question) => !_favoriteQuestionIds.contains(question.id),
      ),
    ];
  }

  List<PokemonQuestionDefinition> _visibleQuestions(
    List<PokemonQuestionDefinition> questions,
  ) {
    final query = _questionSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return questions;
    }

    return questions
        .where((question) => question.label.toLowerCase().contains(query))
        .toList();
  }

  int _questionCountForCategory(
    List<PokemonQuestionDefinition> availableQuestions,
    String category,
  ) {
    return availableQuestions
        .where((question) => question.category == category)
        .length;
  }

  void _selectAvailableQuestion({
    List<_AskedQuestion>? askedQuestions,
    String? preferredCategory,
  }) {
    final availableQuestions = _availableQuestions(askedQuestions);
    final categories = _availableCategories(availableQuestions);
    final category =
        preferredCategory != null && categories.contains(preferredCategory)
        ? preferredCategory
        : categories.firstOrNull;

    _selectedCategory = category;
    _selectedQuestionId = _questionsForCategory(
      availableQuestions,
      category,
    ).firstOrNull?.id;
  }

  int _dailyIndex(int length, DateTime date) {
    final seed = date.year * 1000 + date.month * 40 + date.day + 191;
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
    return GameRevealPanel(
      isRevealed: isRevealed,
      hidden: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(
              height: 132,
              child: Icon(Icons.question_mark, size: 72),
            ),
            const SizedBox(height: 8),
            Text(
              'Pokemon oculto',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(dateKey, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      revealed: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 168,
              child: target.imageUrl != null
                  ? Image.network(
                      target.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.catching_pokemon, size: 56);
                      },
                    )
                  : const Icon(Icons.catching_pokemon, size: 72),
            ),
            const SizedBox(height: 8),
            Text(
              target.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(dateKey, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            PokemonTypeChips(
              types: target.types,
              alignment: WrapAlignment.center,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  icon: Icons.public,
                  label: target.region ?? 'Region sin datos',
                ),
                if (target.habitat != null)
                  _SummaryChip(
                    icon: Icons.landscape_outlined,
                    label: target.habitat!,
                  ),
                _SummaryChip(
                  icon: Icons.history,
                  label: 'Gen ${target.generation ?? '-'}',
                ),
                _SummaryChip(
                  icon: Icons.auto_awesome_outlined,
                  label: target.formLabel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(label: 'Altura', value: target.height),
                ),
                Expanded(
                  child: _SummaryMetric(label: 'Peso', value: target.weight),
                ),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Stat principal',
                    value: _highestStatLabel(target),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _highestStatLabel(PokemonPreview pokemon) {
    if (pokemon.stats.isEmpty) {
      return '-';
    }

    final stats = [...pokemon.stats]
      ..sort((first, second) => second.value.compareTo(first.value));
    return '${stats.first.name} ${stats.first.value}';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 17), label: Text(label));
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final autocomplete = Autocomplete<PokemonPreview>(
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
        );
        final submitButton = FilledButton(
          onPressed: enabled ? onSubmit : null,
          child: const Text('Adivinar'),
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [autocomplete, const SizedBox(height: 8), submitButton],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: autocomplete),
            const SizedBox(width: 8),
            submitButton,
          ],
        );
      },
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

class _AskedQuestion {
  const _AskedQuestion({required this.question, required this.answer});

  final PokemonQuestionDefinition question;
  final bool answer;
}
