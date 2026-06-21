import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import 'pokemon_rarity_badge.dart';
import 'pokemon_type_colors.dart';
import 'pokemon_type_chips.dart';

class PokemonCard extends StatelessWidget {
  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.isFavorite,
    this.onTap,
    this.onFavoritePressed,
  });

  final PokemonPreview pokemon;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: pokemonTypeGradient(pokemon.types),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            clipBehavior: Clip.antiAlias,
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PokemonRarityBadge(pokemon: pokemon),
                  IconButton(
                    tooltip: isFavorite
                        ? 'Quitar favorito'
                        : 'Agregar favorito',
                    icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                    color: isFavorite ? Colors.amber : null,
                    onPressed: onFavoritePressed,
                  ),
                ],
              ),
            ),
          ),
        ),
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
