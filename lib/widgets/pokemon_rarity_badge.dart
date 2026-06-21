import 'package:flutter/material.dart';

import '../models/pokemon_preview.dart';

class PokemonRarityBadge extends StatelessWidget {
  const PokemonRarityBadge({super.key, required this.pokemon});

  final PokemonPreview pokemon;

  @override
  Widget build(BuildContext context) {
    final label = pokemon.isMythical
        ? 'M'
        : pokemon.isLegendary
        ? 'L'
        : null;

    if (label == null) {
      return const SizedBox.shrink();
    }

    final color = pokemon.isMythical
        ? const Color(0xFF8E24AA)
        : const Color(0xFFF9A825);

    return Tooltip(
      message: pokemon.isMythical ? 'Mitico' : 'Legendario',
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
