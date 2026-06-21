import 'dart:async';

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

const _statFilters = <_StatFilter>[
  _StatFilter(name: 'hp', label: 'HP'),
  _StatFilter(name: 'attack', label: 'Ataque'),
  _StatFilter(name: 'defense', label: 'Defensa'),
  _StatFilter(name: 'specialAttack', label: 'Ataque esp.'),
  _StatFilter(name: 'specialDefense', label: 'Defensa esp.'),
  _StatFilter(name: 'speed', label: 'Velocidad'),
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
  final TextEditingController _moveSearchController = TextEditingController();
  List<PokemonPreview> _pokemon = [];
  Set<int> _favoritePokemonIds = {};
  final Map<int, PokemonPreview> _metadataById = {};
  final Map<int, PokemonPreview> _detailById = {};
  final Map<String, RangeValues> _statRanges = {
    for (final stat in _statFilters) stat.name: const RangeValues(0, 255),
  };
  String _searchText = '';
  String _moveSearchText = '';
  GenerationFilter? _selectedGeneration;
  PokedexTypeCompositionFilter _typeCompositionFilter =
      PokedexTypeCompositionFilter.any;
  PokedexRarityFilter _rarityFilter = PokedexRarityFilter.any;
  PokemonEvolutionStage? _selectedEvolutionStage;
  String? _errorMessage;
  PokedexViewMode _viewMode = PokedexViewMode.list;
  PokedexSortMode _sortMode = PokedexSortMode.numberAsc;
  var _isLoading = true;
  var _isLoadingAdvancedData = false;
  var _isLoadingMetadataForBadges = false;
  var _metadataRequestToken = 0;

  @override
  void initState() {
    super.initState();
    _loadPokemon();
    _loadFavoritePokemonIds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _moveSearchController.dispose();
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
      unawaited(_loadMetadataForCurrentPokemon(showLoading: false));
      unawaited(_ensureAdvancedDataForActiveFilters());
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
    final filteredPokemon = _pokemon.map(_pokemonWithLoadedData).where((
      pokemon,
    ) {
      final query = _searchText.toLowerCase();
      final name = pokemon.name.toLowerCase();
      final number = pokemon.id.toString().padLeft(3, '0');
      final selectedGeneration = _selectedGeneration;
      final matchesGeneration =
          selectedGeneration == null ||
          (pokemon.id >= selectedGeneration.minId &&
              pokemon.id <= selectedGeneration.maxId);

      return matchesGeneration &&
          (name.contains(query) || number.contains(query)) &&
          _matchesAdvancedFilters(pokemon);
    }).toList()..sort(_sortPokemon);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _SearchAndFilterMenu(
            selectedTypes: _selectedTypes,
            selectedGeneration: _selectedGeneration,
            favoritesOnly: _favoritesOnly,
            typeCompositionFilter: _typeCompositionFilter,
            rarityFilter: _rarityFilter,
            selectedEvolutionStage: _selectedEvolutionStage,
            evolvesByItemOnly: _evolvesByItemOnly,
            moveSearchController: _moveSearchController,
            statRanges: _statRanges,
            isLoadingAdvancedData:
                _isLoadingAdvancedData || _isLoadingMetadataForBadges,
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
            onFavoritesOnlyChanged: (value) {
              setState(() {
                _favoritesOnly = value;
              });
            },
            onTypeCompositionChanged: (value) {
              setState(() {
                _typeCompositionFilter = value;
              });
            },
            onRarityChanged: (value) {
              setState(() {
                _rarityFilter = value;
              });
              unawaited(_ensureAdvancedDataForActiveFilters());
            },
            onEvolutionStageChanged: (value) {
              setState(() {
                _selectedEvolutionStage = value;
              });
              unawaited(_ensureAdvancedDataForActiveFilters());
            },
            onEvolvesByItemChanged: (value) {
              setState(() {
                _evolvesByItemOnly = value;
              });
              unawaited(_ensureAdvancedDataForActiveFilters());
            },
            onMoveSearchChanged: (value) {
              setState(() {
                _moveSearchText = value;
              });
              unawaited(_ensureAdvancedDataForActiveFilters());
            },
            onStatRangeChanged: (statName, value) {
              setState(() {
                _statRanges[statName] = value;
              });
              unawaited(_ensureAdvancedDataForActiveFilters());
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

  bool _favoritesOnly = false;
  bool _evolvesByItemOnly = false;

  bool _matchesAdvancedFilters(PokemonPreview pokemon) {
    if (_favoritesOnly && !_favoritePokemonIds.contains(pokemon.id)) {
      return false;
    }

    if (!_typeCompositionFilter.matches(pokemon)) {
      return false;
    }

    if (!_rarityFilter.matches(pokemon)) {
      return false;
    }

    final selectedEvolutionStage = _selectedEvolutionStage;
    if (selectedEvolutionStage != null &&
        pokemon.evolutionStage != selectedEvolutionStage) {
      return false;
    }

    if (_evolvesByItemOnly && !pokemon.evolvesByItem) {
      return false;
    }

    if (!_matchesMoveFilter(pokemon)) {
      return false;
    }

    if (!_matchesStatFilters(pokemon)) {
      return false;
    }

    return true;
  }

  bool _matchesMoveFilter(PokemonPreview pokemon) {
    final query = _normalizeSearch(_moveSearchText);
    if (query.isEmpty) {
      return true;
    }

    return pokemon.moves.any((move) {
      return _normalizeSearch(move.name).contains(query) ||
          _normalizeSearch(move.apiName).contains(query);
    });
  }

  bool _matchesStatFilters(PokemonPreview pokemon) {
    for (final filter in _statFilters) {
      final range = _statRanges[filter.name] ?? const RangeValues(0, 255);
      if (range.start <= 0 && range.end >= 255) {
        continue;
      }

      int? statValue;
      for (final stat in pokemon.stats) {
        if (stat.name == filter.label) {
          statValue = stat.value;
          break;
        }
      }
      if (statValue == null ||
          statValue < range.start.round() ||
          statValue > range.end.round()) {
        return false;
      }
    }

    return true;
  }

  String _normalizeSearch(String value) {
    return value.toLowerCase().trim().replaceAll(' ', '-');
  }

  PokemonPreview _pokemonWithLoadedData(PokemonPreview pokemon) {
    final detail = _detailById[pokemon.id];
    if (detail != null) {
      return _mergePokemonData(pokemon, detail);
    }

    final metadata = _metadataById[pokemon.id];
    if (metadata != null) {
      return _mergePokemonData(pokemon, metadata);
    }

    return pokemon;
  }

  PokemonPreview _mergePokemonData(PokemonPreview base, PokemonPreview extra) {
    return base.copyWith(
      name: extra.name,
      types: extra.types.isEmpty ? base.types : extra.types,
      description: extra.description,
      height: extra.height,
      weight: extra.weight,
      imageUrl: extra.imageUrl ?? base.imageUrl,
      abilities: extra.abilities.isEmpty ? base.abilities : extra.abilities,
      stats: extra.stats.isEmpty ? base.stats : extra.stats,
      moves: extra.moves.isEmpty ? base.moves : extra.moves,
      isLegendary: extra.isLegendary,
      isMythical: extra.isMythical,
      evolvesByItem: extra.evolvesByItem,
      evolutionStage: extra.evolutionStage,
      evolutionLine: extra.evolutionLine,
    );
  }

  bool get _hasMetadataFilters {
    return _rarityFilter != PokedexRarityFilter.any ||
        _selectedEvolutionStage != null ||
        _evolvesByItemOnly;
  }

  bool get _hasDetailFilters {
    return _moveSearchText.trim().isNotEmpty ||
        _statRanges.values.any((range) {
          return range.start > 0 || range.end < 255;
        });
  }

  Future<void> _ensureAdvancedDataForActiveFilters() async {
    if (_hasDetailFilters) {
      await _loadDetailsForCurrentPokemon();
      return;
    }

    if (_hasMetadataFilters) {
      await _loadMetadataForCurrentPokemon(showLoading: true);
    }
  }

  Future<void> _loadMetadataForCurrentPokemon({
    required bool showLoading,
  }) async {
    if (_pokemon.isEmpty) {
      return;
    }

    final token = ++_metadataRequestToken;
    final missingPokemon = [
      for (final pokemon in _pokemon)
        if (!_metadataById.containsKey(pokemon.id) &&
            !_detailById.containsKey(pokemon.id))
          pokemon,
    ];

    if (missingPokemon.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        if (showLoading) {
          _isLoadingAdvancedData = true;
        } else {
          _isLoadingMetadataForBadges = true;
        }
      });
    }

    final loaded = <int, PokemonPreview>{};
    try {
      for (var index = 0; index < missingPokemon.length; index += 20) {
        final batch = missingPokemon.skip(index).take(20).toList();
        final metadata = await Future.wait(
          batch.map((pokemon) {
            return widget.pokemonRepository.fetchPokemonMetadata(pokemon.id);
          }),
        );

        for (final item in metadata) {
          loaded[item.id] = item;
        }
      }
    } catch (_) {
      // Advanced metadata is optional; the catalog remains usable if it fails.
    }

    if (!mounted || token != _metadataRequestToken) {
      return;
    }

    setState(() {
      _metadataById.addAll(loaded);
      if (showLoading) {
        _isLoadingAdvancedData = false;
      } else {
        _isLoadingMetadataForBadges = false;
      }
    });
  }

  Future<void> _loadDetailsForCurrentPokemon() async {
    if (_pokemon.isEmpty || _isLoadingAdvancedData) {
      return;
    }

    final missingPokemon = [
      for (final pokemon in _pokemon)
        if (!_detailById.containsKey(pokemon.id)) pokemon,
    ];

    if (missingPokemon.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingAdvancedData = true;
    });

    final loaded = <int, PokemonPreview>{};
    try {
      for (var index = 0; index < missingPokemon.length; index += 12) {
        final batch = missingPokemon.skip(index).take(12).toList();
        final details = await Future.wait(
          batch.map((pokemon) {
            return widget.pokemonRepository.fetchPokemonDetail(pokemon.id);
          }),
        );

        for (final item in details) {
          loaded[item.id] = item;
        }
      }
    } catch (_) {
      // The visible catalog stays available if an advanced filter fetch fails.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _detailById.addAll(loaded);
      _isLoadingAdvancedData = false;
    });
  }

  void _clearFilters() {
    final hadTypeFilters = _selectedTypes.isNotEmpty;

    setState(() {
      _selectedTypes.clear();
      _selectedGeneration = null;
      _favoritesOnly = false;
      _typeCompositionFilter = PokedexTypeCompositionFilter.any;
      _rarityFilter = PokedexRarityFilter.any;
      _selectedEvolutionStage = null;
      _evolvesByItemOnly = false;
      _moveSearchText = '';
      _moveSearchController.clear();
      for (final stat in _statFilters) {
        _statRanges[stat.name] = const RangeValues(0, 255);
      }
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

enum PokedexTypeCompositionFilter {
  any,
  monotype,
  dualType;

  String get label {
    return switch (this) {
      PokedexTypeCompositionFilter.any => 'Todos',
      PokedexTypeCompositionFilter.monotype => 'Monotipo',
      PokedexTypeCompositionFilter.dualType => 'Doble tipo',
    };
  }

  bool matches(PokemonPreview pokemon) {
    return switch (this) {
      PokedexTypeCompositionFilter.any => true,
      PokedexTypeCompositionFilter.monotype => pokemon.types.length == 1,
      PokedexTypeCompositionFilter.dualType => pokemon.types.length >= 2,
    };
  }
}

enum PokedexRarityFilter {
  any,
  normal,
  legendary,
  mythical;

  String get label {
    return switch (this) {
      PokedexRarityFilter.any => 'Todos',
      PokedexRarityFilter.normal => 'No legendario/mitico',
      PokedexRarityFilter.legendary => 'Legendario',
      PokedexRarityFilter.mythical => 'Mitico',
    };
  }

  bool matches(PokemonPreview pokemon) {
    return switch (this) {
      PokedexRarityFilter.any => true,
      PokedexRarityFilter.normal => !pokemon.isLegendary && !pokemon.isMythical,
      PokedexRarityFilter.legendary => pokemon.isLegendary,
      PokedexRarityFilter.mythical => pokemon.isMythical,
    };
  }
}

enum PokedexViewMode { list, grid }

class _StatFilter {
  const _StatFilter({required this.name, required this.label});

  final String name;
  final String label;
}

class _SearchAndFilterMenu extends StatelessWidget {
  const _SearchAndFilterMenu({
    required this.selectedTypes,
    required this.selectedGeneration,
    required this.favoritesOnly,
    required this.typeCompositionFilter,
    required this.rarityFilter,
    required this.selectedEvolutionStage,
    required this.evolvesByItemOnly,
    required this.moveSearchController,
    required this.statRanges,
    required this.isLoadingAdvancedData,
    required this.sortMode,
    required this.searchController,
    required this.onSearchChanged,
    required this.onTypeToggled,
    required this.onGenerationChanged,
    required this.onFavoritesOnlyChanged,
    required this.onTypeCompositionChanged,
    required this.onRarityChanged,
    required this.onEvolutionStageChanged,
    required this.onEvolvesByItemChanged,
    required this.onMoveSearchChanged,
    required this.onStatRangeChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  final Set<String> selectedTypes;
  final GenerationFilter? selectedGeneration;
  final bool favoritesOnly;
  final PokedexTypeCompositionFilter typeCompositionFilter;
  final PokedexRarityFilter rarityFilter;
  final PokemonEvolutionStage? selectedEvolutionStage;
  final bool evolvesByItemOnly;
  final TextEditingController moveSearchController;
  final Map<String, RangeValues> statRanges;
  final bool isLoadingAdvancedData;
  final PokedexSortMode sortMode;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeToggled;
  final ValueChanged<GenerationFilter?> onGenerationChanged;
  final ValueChanged<bool> onFavoritesOnlyChanged;
  final ValueChanged<PokedexTypeCompositionFilter> onTypeCompositionChanged;
  final ValueChanged<PokedexRarityFilter> onRarityChanged;
  final ValueChanged<PokemonEvolutionStage?> onEvolutionStageChanged;
  final ValueChanged<bool> onEvolvesByItemChanged;
  final ValueChanged<String> onMoveSearchChanged;
  final void Function(String statName, RangeValues range) onStatRangeChanged;
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
          constraints: const BoxConstraints(maxHeight: 320),
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Solo favoritos'),
                  value: favoritesOnly,
                  onChanged: onFavoritesOnlyChanged,
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
                DropdownButtonFormField<PokedexTypeCompositionFilter>(
                  key: ValueKey(
                    'typeComposition-${typeCompositionFilter.name}',
                  ),
                  initialValue: typeCompositionFilter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Composicion de tipos',
                  ),
                  items: [
                    for (final filter in PokedexTypeCompositionFilter.values)
                      DropdownMenuItem(
                        value: filter,
                        child: Text(filter.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onTypeCompositionChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PokedexRarityFilter>(
                  key: ValueKey('rarityFilter-${rarityFilter.name}'),
                  initialValue: rarityFilter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Rareza',
                  ),
                  items: [
                    for (final filter in PokedexRarityFilter.values)
                      DropdownMenuItem(
                        value: filter,
                        child: Text(filter.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onRarityChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PokemonEvolutionStage?>(
                  key: ValueKey(
                    'evolutionStage-${selectedEvolutionStage?.name ?? 'all'}',
                  ),
                  initialValue: selectedEvolutionStage,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Etapa evolutiva',
                  ),
                  items: [
                    const DropdownMenuItem<PokemonEvolutionStage?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final stage in PokemonEvolutionStage.values)
                      if (stage != PokemonEvolutionStage.unknown)
                        DropdownMenuItem<PokemonEvolutionStage?>(
                          value: stage,
                          child: Text(stage.label),
                        ),
                  ],
                  onChanged: onEvolutionStageChanged,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Evoluciona con objeto'),
                  value: evolvesByItemOnly,
                  onChanged: onEvolvesByItemChanged,
                ),
                TextField(
                  key: const ValueKey('moveSearchField'),
                  controller: moveSearchController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Movimiento que puede aprender',
                    prefixIcon: Icon(Icons.auto_fix_high),
                  ),
                  onChanged: onMoveSearchChanged,
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Rangos de stats'),
                  subtitle: const Text('HP, ataques, defensas y velocidad'),
                  children: [
                    for (final stat in _statFilters)
                      _StatRangeSlider(
                        stat: stat,
                        range:
                            statRanges[stat.name] ?? const RangeValues(0, 255),
                        onChanged: (range) {
                          onStatRangeChanged(stat.name, range);
                        },
                      ),
                  ],
                ),
                if (isLoadingAdvancedData) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
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

class _StatRangeSlider extends StatelessWidget {
  const _StatRangeSlider({
    required this.stat,
    required this.range,
    required this.onChanged,
  });

  final _StatFilter stat;
  final RangeValues range;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final start = range.start.round();
    final end = range.end.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${stat.label}: $start-$end'),
        RangeSlider(
          values: range,
          min: 0,
          max: 255,
          divisions: 51,
          labels: RangeLabels('$start', '$end'),
          onChanged: onChanged,
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
