import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import '../services/pokemon_repository.dart';
import '../services/user_data_repository.dart';
import '../widgets/pokemon_type_chips.dart';

class PokemonDetailPage extends StatefulWidget {
  const PokemonDetailPage({
    super.key,
    required this.pokemon,
    required this.pokemonRepository,
    required this.userDataRepository,
  });

  final PokemonPreview pokemon;
  final PokemonRepository pokemonRepository;
  final UserDataRepository userDataRepository;

  @override
  State<PokemonDetailPage> createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage> {
  var _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final favoritePokemonIds = await widget.userDataRepository
        .readFavoritePokemonIds();

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavorite = favoritePokemonIds.contains(widget.pokemon.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final favoritePokemonIds = await widget.userDataRepository
        .readFavoritePokemonIds();

    if (favoritePokemonIds.contains(widget.pokemon.id)) {
      favoritePokemonIds.remove(widget.pokemon.id);
    } else {
      favoritePokemonIds.add(widget.pokemon.id);
    }

    await widget.userDataRepository.writeFavoritePokemonIds(favoritePokemonIds);

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavorite = favoritePokemonIds.contains(widget.pokemon.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pokemon.name),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Quitar favorito' : 'Agregar favorito',
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            color: _isFavorite ? Colors.amber : null,
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: FutureBuilder<PokemonPreview>(
        future: widget.pokemonRepository.fetchPokemonDetail(widget.pokemon.id),
        initialData: widget.pokemon,
        builder: (context, snapshot) {
          final detail = snapshot.data ?? widget.pokemon;

          if (snapshot.hasError) {
            return _PokemonDetailContent(
              pokemon: widget.pokemon,
              pokemonRepository: widget.pokemonRepository,
              footer: const Text('No se pudo cargar el detalle completo'),
            );
          }

          return _PokemonDetailContent(
            pokemon: detail,
            pokemonRepository: widget.pokemonRepository,
            footer: snapshot.connectionState == ConnectionState.waiting
                ? const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _PokemonDetailContent extends StatelessWidget {
  const _PokemonDetailContent({
    required this.pokemon,
    required this.pokemonRepository,
    this.footer,
  });

  final PokemonPreview pokemon;
  final PokemonRepository pokemonRepository;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PokemonSpriteShowcase(pokemon: pokemon),
        const SizedBox(height: 16),
        Text(
          pokemon.name,
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(
          child: PokemonTypeChips(
            types: pokemon.types,
            alignment: WrapAlignment.center,
          ),
        ),
        const SizedBox(height: 24),
        Text(pokemon.description, style: textTheme.bodyLarge),
        const SizedBox(height: 24),
        _PokemonFact(label: 'Altura', value: pokemon.height),
        _PokemonFact(label: 'Peso', value: pokemon.weight),
        const SizedBox(height: 24),
        _EvolutionSection(evolutionLine: pokemon.evolutionLine),
        const SizedBox(height: 24),
        _AbilitiesSection(
          abilities: pokemon.abilities,
          pokemonRepository: pokemonRepository,
        ),
        const SizedBox(height: 24),
        _StatsSection(stats: pokemon.stats),
        const SizedBox(height: 24),
        _MovesSection(
          moves: pokemon.moves,
          pokemonRepository: pokemonRepository,
        ),
        ?footer,
      ],
    );
  }
}

class _EvolutionSection extends StatelessWidget {
  const _EvolutionSection({required this.evolutionLine});

  final List<PokemonEvolutionStep> evolutionLine;

  @override
  Widget build(BuildContext context) {
    if (evolutionLine.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Linea evolutiva', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final step in evolutionLine) ...[
                ListTile(
                  leading: CircleAvatar(
                    child: Text('#${step.id.toString().padLeft(3, '0')}'),
                  ),
                  title: Text(step.name),
                  subtitle: Text(step.method),
                ),
                if (step != evolutionLine.last) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AbilitiesSection extends StatelessWidget {
  const _AbilitiesSection({
    required this.abilities,
    required this.pokemonRepository,
  });

  final List<PokemonAbility> abilities;
  final PokemonRepository pokemonRepository;

  @override
  Widget build(BuildContext context) {
    if (abilities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habilidades', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ability in abilities)
              ActionChip(
                label: Text(ability.name),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => _AbilityDialog(
                      ability: ability,
                      pokemonRepository: pokemonRepository,
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _MovesSection extends StatelessWidget {
  const _MovesSection({required this.moves, required this.pokemonRepository});

  final List<PokemonMoveSummary> moves;
  final PokemonRepository pokemonRepository;

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedMoves = <String, List<PokemonMoveSummary>>{};
    for (final move in moves) {
      groupedMoves.putIfAbsent(move.learnMethod, () => []).add(move);
    }

    for (final moveGroup in groupedMoves.values) {
      moveGroup.sort(_compareMoves);
    }

    final orderedMethods = groupedMoves.keys.toList()..sort(_compareMethods);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Movimientos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final method in orderedMethods)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(method),
            subtitle: Text('${groupedMoves[method]!.length} movimientos'),
            children: [
              for (final move in groupedMoves[method]!)
                _MoveListTile(move: move, pokemonRepository: pokemonRepository),
            ],
          ),
      ],
    );
  }

  int _compareMoves(PokemonMoveSummary first, PokemonMoveSummary second) {
    final levelCompare = first.level.compareTo(second.level);
    if (levelCompare != 0) {
      return levelCompare;
    }

    return first.name.compareTo(second.name);
  }

  int _compareMethods(String first, String second) {
    final firstIndex = _methodOrder(first);
    final secondIndex = _methodOrder(second);

    if (firstIndex != secondIndex) {
      return firstIndex.compareTo(secondIndex);
    }

    return first.compareTo(second);
  }

  int _methodOrder(String method) {
    return switch (method) {
      'Nivel' => 0,
      'Maquina' => 1,
      'Huevo' => 2,
      'Tutor' => 3,
      _ => 4,
    };
  }
}

class _MoveListTile extends StatelessWidget {
  const _MoveListTile({required this.move, required this.pokemonRepository});

  final PokemonMoveSummary move;
  final PokemonRepository pokemonRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PokemonMoveDetail>(
      future: pokemonRepository.fetchMoveDetail(move.apiName),
      builder: (context, snapshot) {
        final detail = snapshot.data;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(move.name),
          subtitle: Text(
            detail == null
                ? _moveSubtitle(move)
                : '${_moveSubtitle(move)} - Tipo ${detail.type} - Clase '
                      '${detail.damageClass} - Poder ${detail.power ?? '-'} - '
                      'PP ${detail.pp}',
          ),
          trailing: const Icon(Icons.info_outline),
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (_) =>
                  _MoveDialog(move: move, pokemonRepository: pokemonRepository),
            );
          },
        );
      },
    );
  }

  String _moveSubtitle(PokemonMoveSummary move) {
    if (move.learnMethod == 'Nivel' && move.level > 0) {
      return 'Nivel ${move.level}';
    }

    return move.learnMethod;
  }
}

class _AbilityDialog extends StatelessWidget {
  const _AbilityDialog({
    required this.ability,
    required this.pokemonRepository,
  });

  final PokemonAbility ability;
  final PokemonRepository pokemonRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PokemonAbilityDetail>(
      future: pokemonRepository.fetchAbilityDetail(ability.apiName),
      builder: (context, snapshot) {
        final detail = snapshot.data;

        return AlertDialog(
          title: Text(detail?.name ?? ability.name),
          content: snapshot.connectionState == ConnectionState.waiting
              ? const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                )
              : snapshot.hasError || detail == null
              ? const Text('No se pudo cargar la habilidad')
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogFact(
                        label: 'Nombre en ingles',
                        value: detail.englishName,
                      ),
                      const SizedBox(height: 12),
                      Text(detail.description),
                      const SizedBox(height: 12),
                      _DialogSection(
                        title: 'Descripcion en ingles',
                        value: detail.englishDescription,
                      ),
                      const SizedBox(height: 12),
                      _DialogSection(
                        title: 'Detalle tecnico',
                        value: detail.technicalDetail,
                      ),
                    ],
                  ),
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
}

class _MoveDialog extends StatelessWidget {
  const _MoveDialog({required this.move, required this.pokemonRepository});

  final PokemonMoveSummary move;
  final PokemonRepository pokemonRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PokemonMoveDetail>(
      future: pokemonRepository.fetchMoveDetail(move.apiName),
      builder: (context, snapshot) {
        final detail = snapshot.data;

        return AlertDialog(
          title: Text(detail?.name ?? move.name),
          content: snapshot.connectionState == ConnectionState.waiting
              ? const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                )
              : snapshot.hasError || detail == null
              ? const Text('No se pudo cargar el movimiento')
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogFact(
                        label: 'Nombre en ingles',
                        value: detail.englishName,
                      ),
                      _DialogFact(label: 'Tipo', value: detail.type),
                      _DialogFact(label: 'Clase', value: detail.damageClass),
                      _DialogFact(
                        label: 'Poder',
                        value: detail.power?.toString() ?? '-',
                      ),
                      _DialogFact(label: 'PP', value: '${detail.pp}'),
                      _DialogFact(
                        label: 'Precision',
                        value: detail.accuracy == null
                            ? '-'
                            : '${detail.accuracy}%',
                      ),
                      const SizedBox(height: 12),
                      Text(detail.description),
                      const SizedBox(height: 12),
                      _DialogSection(
                        title: 'Detalle tecnico',
                        value: detail.technicalDetail,
                      ),
                    ],
                  ),
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
}

class _DialogFact extends StatelessWidget {
  const _DialogFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}

class _DialogSection extends StatelessWidget {
  const _DialogSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats});

  final List<PokemonStat> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stats', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final stat in stats) _StatRow(stat: stat),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final PokemonStat stat;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = (stat.value / 150).clamp(0.0, 1.0);
    final statColor = _statColor(stat.value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 96, child: Text(stat.name)),
          SizedBox(width: 36, child: Text('${stat.value}')),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: normalizedValue,
                color: statColor,
                backgroundColor: statColor.withValues(alpha: 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statColor(int value) {
    if (value < 50) {
      return const Color(0xFFE53935);
    }

    if (value < 80) {
      return const Color(0xFFFB8C00);
    }

    if (value < 100) {
      return const Color(0xFFFDD835);
    }

    return const Color(0xFF43A047);
  }
}

class _PokemonSpriteShowcase extends StatefulWidget {
  const _PokemonSpriteShowcase({required this.pokemon});

  final PokemonPreview pokemon;

  @override
  State<_PokemonSpriteShowcase> createState() => _PokemonSpriteShowcaseState();
}

class _PokemonSpriteShowcaseState extends State<_PokemonSpriteShowcase> {
  var _isShiny = false;

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    final frontImageUrl = _isShiny
        ? pokemon.frontShinySpriteUrl ??
              pokemon.frontSpriteUrl ??
              pokemon.imageUrl
        : pokemon.frontSpriteUrl ?? pokemon.imageUrl;
    final backImageUrl = _isShiny
        ? pokemon.backShinySpriteUrl ?? pokemon.backSpriteUrl
        : pokemon.backSpriteUrl;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SpriteSlot(label: 'Frente', imageUrl: frontImageUrl),
            const SizedBox(width: 16),
            _SpriteSlot(label: 'Espalda', imageUrl: backImageUrl),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.catching_pokemon),
              label: Text('Normal'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.auto_awesome),
              label: Text('Shiny'),
            ),
          ],
          selected: {_isShiny},
          onSelectionChanged: (selection) {
            setState(() {
              _isShiny = selection.first;
            });
          },
        ),
      ],
    );
  }
}

class _SpriteSlot extends StatelessWidget {
  const _SpriteSlot({required this.label, required this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        children: [
          Container(
            height: 132,
            width: 132,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl == null
                ? const Icon(Icons.catching_pokemon, size: 42)
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.catching_pokemon, size: 42);
                    },
                  ),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _PokemonFact extends StatelessWidget {
  const _PokemonFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value),
    );
  }
}
