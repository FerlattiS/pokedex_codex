import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import '../services/pokemon_repository.dart';
import '../services/user_data_repository.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_page.dart';

class DailyRandommonPage extends StatefulWidget {
  const DailyRandommonPage({
    super.key,
    required this.pokemonRepository,
    required this.userDataRepository,
    this.date,
  });

  final PokemonRepository pokemonRepository;
  final UserDataRepository userDataRepository;
  final DateTime? date;

  @override
  State<DailyRandommonPage> createState() => _DailyRandommonPageState();
}

class _DailyRandommonPageState extends State<DailyRandommonPage> {
  late Future<PokemonPreview> _dailyPokemonFuture;
  Set<int> _favoritePokemonIds = {};

  @override
  void initState() {
    super.initState();
    _dailyPokemonFuture = _loadDailyPokemon();
    _loadFavoritePokemonIds();
  }

  Future<PokemonPreview> _loadDailyPokemon() async {
    final pokemon = await widget.pokemonRepository.fetchPokemonCatalog();

    if (pokemon.isEmpty) {
      throw Exception('Catalogo vacio');
    }

    final date = widget.date ?? DateTime.now();
    final seed = date.year * 1000 + date.month * 40 + date.day;
    return pokemon[seed % pokemon.length];
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PokemonPreview>(
      future: _dailyPokemonFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo cargar el Randommon diario'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _dailyPokemonFuture = _loadDailyPokemon();
                    });
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final pokemon = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Pokemon de hoy',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PokemonCard(
              pokemon: pokemon,
              isFavorite: _favoritePokemonIds.contains(pokemon.id),
              onTap: () => _openPokemonDetail(pokemon),
              onFavoritePressed: () => _toggleFavorite(pokemon),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openPokemonDetail(pokemon),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver detalle'),
            ),
          ],
        );
      },
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
}
