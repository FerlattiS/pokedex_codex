import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import '../services/pokemon_repository.dart';
import '../services/user_data_repository.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/pokemon_grid_tile.dart';
import 'pokemon_detail_page.dart';

const _typeFilters = <PokemonTypeFilter>[
  PokemonTypeFilter(label: 'Normal', value: 'normal'),
  PokemonTypeFilter(label: 'Fuego', value: 'fire'),
  PokemonTypeFilter(label: 'Agua', value: 'water'),
  PokemonTypeFilter(label: 'Electrico', value: 'electric'),
  PokemonTypeFilter(label: 'Planta', value: 'grass'),
  PokemonTypeFilter(label: 'Hielo', value: 'ice'),
  PokemonTypeFilter(label: 'Lucha', value: 'fighting'),
  PokemonTypeFilter(label: 'Veneno', value: 'poison'),
  PokemonTypeFilter(label: 'Tierra', value: 'ground'),
  PokemonTypeFilter(label: 'Volador', value: 'flying'),
  PokemonTypeFilter(label: 'Psiquico', value: 'psychic'),
  PokemonTypeFilter(label: 'Bicho', value: 'bug'),
  PokemonTypeFilter(label: 'Roca', value: 'rock'),
  PokemonTypeFilter(label: 'Fantasma', value: 'ghost'),
  PokemonTypeFilter(label: 'Dragon', value: 'dragon'),
  PokemonTypeFilter(label: 'Siniestro', value: 'dark'),
  PokemonTypeFilter(label: 'Acero', value: 'steel'),
  PokemonTypeFilter(label: 'Hada', value: 'fairy'),
];

const _generationFilters = <GenerationFilter>[
  GenerationFilter(label: 'Gen 1', minId: 1, maxId: 151),
  GenerationFilter(label: 'Gen 2', minId: 152, maxId: 251),
  GenerationFilter(label: 'Gen 3', minId: 252, maxId: 386),
  GenerationFilter(label: 'Gen 4', minId: 387, maxId: 493),
  GenerationFilter(label: 'Gen 5', minId: 494, maxId: 649),
  GenerationFilter(label: 'Gen 6', minId: 650, maxId: 721),
  GenerationFilter(label: 'Gen 7', minId: 722, maxId: 809),
  GenerationFilter(label: 'Gen 8', minId: 810, maxId: 905),
  GenerationFilter(label: 'Gen 9', minId: 906, maxId: 1025),
];

class PokedexHomePage extends StatefulWidget {
  const PokedexHomePage({
    super.key,
    required this.pokemonRepository,
    required this.userDataRepository,
  });

  final PokemonRepository pokemonRepository;
  final UserDataRepository userDataRepository;

  @override
  State<PokedexHomePage> createState() => _PokedexHomePageState();
}

class _PokedexHomePageState extends State<PokedexHomePage> {
  final Set<String> _selectedTypes = {};
  final TextEditingController _searchController = TextEditingController();
  List<PokemonPreview> _pokemon = [];
  Set<int> _favoritePokemonIds = {};
  String _searchText = '';
  GenerationFilter? _selectedGeneration;
  String? _errorMessage;
  PokedexViewMode _viewMode = PokedexViewMode.list;
  PokedexSortMode _sortMode = PokedexSortMode.numberAsc;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPokemon();
    _loadFavoritePokemonIds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPokemon() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final pokemon = _selectedTypes.isEmpty
          ? await widget.pokemonRepository.fetchPokemonCatalog()
          : await widget.pokemonRepository.fetchPokemonByTypes(
              _selectedTypes.toList(),
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _pokemon = pokemon;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudo cargar la Pokedex';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoritePokemonIds() async {
    final favoritePokemonIds = await widget.userDataRepository
        .readFavoritePokemonIds();

    if (!mounted) {
      return;
    }

    setState(() {
      _favoritePokemonIds = favoritePokemonIds;
    });
  }

  Future<void> _toggleFavorite(PokemonPreview pokemon) async {
    final nextFavorites = {..._favoritePokemonIds};
    if (nextFavorites.contains(pokemon.id)) {
      nextFavorites.remove(pokemon.id);
    } else {
      nextFavorites.add(pokemon.id);
    }

    setState(() {
      _favoritePokemonIds = nextFavorites;
    });

    await widget.userDataRepository.writeFavoritePokemonIds(nextFavorites);
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
    _loadPokemon();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPokemon = _pokemon.where((pokemon) {
      final query = _searchText.toLowerCase();
      final name = pokemon.name.toLowerCase();
      final number = pokemon.id.toString().padLeft(3, '0');
      final selectedGeneration = _selectedGeneration;
      final matchesGeneration =
          selectedGeneration == null ||
          (pokemon.id >= selectedGeneration.minId &&
              pokemon.id <= selectedGeneration.maxId);

      return matchesGeneration &&
          (name.contains(query) || number.contains(query));
    }).toList()..sort(_sortPokemon);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _SearchAndFilterMenu(
            selectedTypes: _selectedTypes,
            selectedGeneration: _selectedGeneration,
            sortMode: _sortMode,
            searchController: _searchController,
            onSearchChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            onTypeToggled: _toggleType,
            onGenerationChanged: (value) {
              setState(() {
                _selectedGeneration = value;
              });
            },
            onSortChanged: (value) {
              setState(() {
                _sortMode = value;
              });
            },
            onClearFilters: _clearFilters,
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Expanded(child: _LoadingView())
          else if (_errorMessage != null)
            Expanded(child: _ErrorView(onRetry: _loadPokemon))
          else ...[
            _ResultsHeader(
              count: filteredPokemon.length,
              viewMode: _viewMode,
              onViewChanged: (value) {
                setState(() {
                  _viewMode = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredPokemon.isEmpty
                  ? const Center(child: Text('No hay Pokemon para mostrar'))
                  : _viewMode == PokedexViewMode.list
                  ? _PokemonList(
                      pokemon: filteredPokemon,
                      favoritePokemonIds: _favoritePokemonIds,
                      onPokemonSelected: _openPokemonDetail,
                      onFavoriteToggled: _toggleFavorite,
                    )
                  : _PokemonGrid(
                      pokemon: filteredPokemon,
                      favoritePokemonIds: _favoritePokemonIds,
                      onPokemonSelected: _openPokemonDetail,
                      onFavoriteToggled: _toggleFavorite,
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openPokemonDetail(PokemonPreview pokemon) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PokemonDetailPage(
          pokemon: pokemon,
          pokemonRepository: widget.pokemonRepository,
          userDataRepository: widget.userDataRepository,
        ),
      ),
    );
    await _loadFavoritePokemonIds();
  }

  int _sortPokemon(PokemonPreview first, PokemonPreview second) {
    return switch (_sortMode) {
      PokedexSortMode.numberAsc => first.id.compareTo(second.id),
      PokedexSortMode.numberDesc => second.id.compareTo(first.id),
      PokedexSortMode.nameAsc => first.name.compareTo(second.name),
      PokedexSortMode.nameDesc => second.name.compareTo(first.name),
    };
  }

  void _clearFilters() {
    final hadTypeFilters = _selectedTypes.isNotEmpty;

    setState(() {
      _selectedTypes.clear();
      _selectedGeneration = null;
      _searchText = '';
      _sortMode = PokedexSortMode.numberAsc;
      _searchController.clear();
    });

    if (hadTypeFilters) {
      _loadPokemon();
    }
  }
}

class PokemonTypeFilter {
  const PokemonTypeFilter({required this.label, required this.value});

  final String label;
  final String value;
}

class GenerationFilter {
  const GenerationFilter({
    required this.label,
    required this.minId,
    required this.maxId,
  });

  final String label;
  final int minId;
  final int maxId;
}

enum PokedexSortMode {
  numberAsc,
  numberDesc,
  nameAsc,
  nameDesc;

  String get label {
    return switch (this) {
      PokedexSortMode.numberAsc => 'Numero ascendente',
      PokedexSortMode.numberDesc => 'Numero descendente',
      PokedexSortMode.nameAsc => 'Nombre A-Z',
      PokedexSortMode.nameDesc => 'Nombre Z-A',
    };
  }
}

enum PokedexViewMode { list, grid }

class _SearchAndFilterMenu extends StatelessWidget {
  const _SearchAndFilterMenu({
    required this.selectedTypes,
    required this.selectedGeneration,
    required this.sortMode,
    required this.searchController,
    required this.onSearchChanged,
    required this.onTypeToggled,
    required this.onGenerationChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  final Set<String> selectedTypes;
  final GenerationFilter? selectedGeneration;
  final PokedexSortMode sortMode;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeToggled;
  final ValueChanged<GenerationFilter?> onGenerationChanged;
  final ValueChanged<PokedexSortMode> onSortChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Busqueda y filtros'),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            key: const ValueKey('filterScrollView'),
            child: Column(
              children: [
                TextField(
                  key: const ValueKey('pokemonSearchField'),
                  controller: searchController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Buscar Pokemon',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: onSearchChanged,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GenerationFilter?>(
                  key: ValueKey(
                    'generationFilter-${selectedGeneration?.label ?? 'all'}',
                  ),
                  initialValue: selectedGeneration,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Generacion',
                  ),
                  items: [
                    const DropdownMenuItem<GenerationFilter?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final generation in _generationFilters)
                      DropdownMenuItem<GenerationFilter?>(
                        value: generation,
                        child: Text(generation.label),
                      ),
                  ],
                  onChanged: onGenerationChanged,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PokedexSortMode>(
                  key: ValueKey('sortFilter-${sortMode.name}'),
                  initialValue: sortMode,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Orden',
                  ),
                  items: [
                    for (final mode in PokedexSortMode.values)
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSortChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in _typeFilters)
                        FilterChip(
                          label: Text(type.label),
                          selected: selectedTypes.contains(type.value),
                          onSelected: (_) => onTypeToggled(type.value),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const ValueKey('clearFiltersButton'),
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Limpiar filtros'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.count,
    required this.viewMode,
    required this.onViewChanged,
  });

  final int count;
  final PokedexViewMode viewMode;
  final ValueChanged<PokedexViewMode> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('$count Pokemon encontrados')),
        SegmentedButton<PokedexViewMode>(
          segments: const [
            ButtonSegment(
              value: PokedexViewMode.list,
              icon: Icon(Icons.view_list),
              tooltip: 'Lista',
            ),
            ButtonSegment(
              value: PokedexViewMode.grid,
              icon: Icon(Icons.grid_view),
              tooltip: 'Cuadricula',
            ),
          ],
          selected: {viewMode},
          showSelectedIcon: false,
          onSelectionChanged: (values) => onViewChanged(values.first),
        ),
      ],
    );
  }
}

class _PokemonList extends StatelessWidget {
  const _PokemonList({
    required this.pokemon,
    required this.favoritePokemonIds,
    required this.onPokemonSelected,
    required this.onFavoriteToggled,
  });

  final List<PokemonPreview> pokemon;
  final Set<int> favoritePokemonIds;
  final ValueChanged<PokemonPreview> onPokemonSelected;
  final ValueChanged<PokemonPreview> onFavoriteToggled;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: pokemon.length,
      itemBuilder: (context, index) {
        final item = pokemon[index];

        return PokemonCard(
          pokemon: item,
          isFavorite: favoritePokemonIds.contains(item.id),
          onTap: () => onPokemonSelected(item),
          onFavoritePressed: () => onFavoriteToggled(item),
        );
      },
    );
  }
}

class _PokemonGrid extends StatelessWidget {
  const _PokemonGrid({
    required this.pokemon,
    required this.favoritePokemonIds,
    required this.onPokemonSelected,
    required this.onFavoriteToggled,
  });

  final List<PokemonPreview> pokemon;
  final Set<int> favoritePokemonIds;
  final ValueChanged<PokemonPreview> onPokemonSelected;
  final ValueChanged<PokemonPreview> onFavoriteToggled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          >= 900 => 5,
          >= 680 => 4,
          >= 460 => 3,
          _ => 2,
        };

        return GridView.builder(
          itemCount: pokemon.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final item = pokemon[index];
            return PokemonGridTile(
              pokemon: item,
              isFavorite: favoritePokemonIds.contains(item.id),
              onTap: () => onPokemonSelected(item),
              onFavoritePressed: () => onFavoriteToggled(item),
            );
          },
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text('No se pudo cargar la Pokedex'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
