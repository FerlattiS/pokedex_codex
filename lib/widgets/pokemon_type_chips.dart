import 'package:flutter/material.dart';

import 'pokemon_type_colors.dart';

class PokemonTypeChips extends StatelessWidget {
  const PokemonTypeChips({
    super.key,
    required this.types,
    this.emptyText = 'Tipos cargando',
    this.alignment = WrapAlignment.start,
  });

  final List<String> types;
  final String emptyText;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return Text(emptyText);
    }

    return Wrap(
      alignment: alignment,
      spacing: 8,
      runSpacing: 8,
      children: [for (final type in types) _PokemonTypeChip(type: type)],
    );
  }
}

class _PokemonTypeChip extends StatelessWidget {
  const _PokemonTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = pokemonTypeColor(type);
    final labelColor = color.computeLuminance() > 0.55
        ? Colors.black87
        : Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          type,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
