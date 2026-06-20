import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import 'pokemon_type_chips.dart';

class PokemonCard extends StatelessWidget {
  const PokemonCard({super.key, required this.pokemon, this.onTap});

  final PokemonPreview pokemon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: _PokemonAvatar(pokemon: pokemon),
        title: Text(pokemon.name, style: textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: PokemonTypeChips(
            types: pokemon.types,
            emptyText: 'Tipos disponibles con filtros',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _PokemonAvatar extends StatelessWidget {
  const _PokemonAvatar({required this.pokemon});

  final PokemonPreview pokemon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = pokemon.imageUrl;

    if (imageUrl == null) {
      return CircleAvatar(
        child: Text('#${pokemon.id.toString().padLeft(3, '0')}'),
      );
    }

    return CircleAvatar(
      backgroundImage: NetworkImage(imageUrl),
      child: const SizedBox.shrink(),
    );
  }
}
