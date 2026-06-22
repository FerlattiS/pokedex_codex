import 'dart:math';

import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import '../models/user_pokemon_data.dart';
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
  final Random _random = Random();
  final TextEditingController _noteController = TextEditingController();
  late Future<PokemonPreview> _shownPokemonFuture;
  Set<int> _favoritePokemonIds = {};
  Map<int, PokemonNote> _notesByPokemonId = {};

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _shownPokemonFuture = _loadDailyPokemon();
    _loadFavoritePokemonIds();
    _loadNotes();
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

  Future<PokemonPreview> _loadRandomPokemon() async {
    final pokemon = await widget.pokemonRepository.fetchPokemonCatalog();
    if (pokemon.isEmpty) {
      throw Exception('Catalogo vacio');
    }

    return pokemon[_random.nextInt(pokemon.length)];
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

  Future<void> _loadNotes() async {
    final notes = await widget.userDataRepository.readNotes();
    if (!mounted) {
      return;
    }

    setState(() {
      _notesByPokemonId = {for (final note in notes) note.pokemonId: note};
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

  Future<void> _saveNote(PokemonPreview pokemon) async {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      await widget.userDataRepository.deleteNote(pokemon.id);
    } else {
      await widget.userDataRepository.writeNote(
        PokemonNote(
          pokemonId: pokemon.id,
          text: text,
          updatedAt: DateTime.now(),
        ),
      );
    }

    await _loadNotes();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nota guardada')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PokemonPreview>(
      future: _shownPokemonFuture,
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
                      _shownPokemonFuture = _loadDailyPokemon();
                    });
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final pokemon = snapshot.data!;
        final note = _notesByPokemonId[pokemon.id];
        if (_noteController.text != (note?.text ?? '')) {
          _noteController.text = note?.text ?? '';
        }

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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _shownPokemonFuture = _loadRandomPokemon();
                });
              },
              icon: const Icon(Icons.shuffle),
              label: const Text('Ver otro aleatorio'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nota rapida',
                hintText: 'Ideas, usos o comentarios sobre este Pokemon',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _saveNote(pokemon),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar nota'),
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
