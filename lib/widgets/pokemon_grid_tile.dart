import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';
import 'pokemon_type_colors.dart';

class PokemonGridTile extends StatelessWidget {
  const PokemonGridTile({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: pokemonTypeGradient(pokemon.types),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: pokemonTypeGradient(pokemon.types),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: _PokemonImage(pokemon: pokemon),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filledTonal(
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: isFavorite
                                ? 'Quitar favorito'
                                : 'Agregar favorito',
                            icon: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              size: 18,
                            ),
                            color: isFavorite ? Colors.amber : null,
                            onPressed: onFavoritePressed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pokemon.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
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

class _PokemonImage extends StatelessWidget {
  const _PokemonImage({required this.pokemon});

  final PokemonPreview pokemon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = pokemon.imageUrl;

    if (imageUrl == null) {
      return Text('#${pokemon.id.toString().padLeft(3, '0')}');
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Text('#${pokemon.id.toString().padLeft(3, '0')}');
      },
    );
  }
}
