import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import '../services/pokemon_repository.dart';
import '../services/user_data_repository.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.pokemonRepository,
    required this.userDataRepository,
  });

  final PokemonRepository pokemonRepository;
  final UserDataRepository userDataRepository;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  var _isLoading = true;
  String? _errorMessage;
  List<PokemonPreview> _favoritePokemon = [];
  Set<int> _favoritePokemonIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favoritePokemonIds = await widget.userDataRepository
          .readFavoritePokemonIds();
      final catalog = await widget.pokemonRepository.fetchPokemonCatalog();
      final favoritePokemon =
          catalog
              .where((pokemon) => favoritePokemonIds.contains(pokemon.id))
              .toList()
            ..sort((first, second) => first.id.compareTo(second.id));

      if (!mounted) {
        return;
      }

      setState(() {
        _favoritePokemonIds = favoritePokemonIds;
        _favoritePokemon = favoritePokemon;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudieron cargar los favoritos';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(PokemonPreview pokemon) async {
    final nextFavorites = {..._favoritePokemonIds}..remove(pokemon.id);

    setState(() {
      _favoritePokemonIds = nextFavorites;
      _favoritePokemon = [
        for (final item in _favoritePokemon)
          if (item.id != pokemon.id) item,
      ];
    });

    await widget.userDataRepository.writeFavoritePokemonIds(nextFavorites);
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
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadFavorites,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_favoritePokemon.isEmpty) {
      return const Center(child: Text('No hay Pokemon favoritos'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _favoritePokemon.length,
      itemBuilder: (context, index) {
        final pokemon = _favoritePokemon[index];

        return PokemonCard(
          pokemon: pokemon,
          isFavorite: true,
          onTap: () => _openPokemonDetail(pokemon),
          onFavoritePressed: () => _toggleFavorite(pokemon),
        );
      },
    );
  }
}
