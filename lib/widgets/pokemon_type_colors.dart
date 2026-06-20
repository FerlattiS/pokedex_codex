import 'package:flutter/material.dart';

const pokemonTypeColors = <String, Color>{
  'Normal': Color(0xFFA8A77A),
  'Fuego': Color(0xFFEE8130),
  'Agua': Color(0xFF6390F0),
  'Electrico': Color(0xFFF7D02C),
  'Planta': Color(0xFF7AC74C),
  'Hielo': Color(0xFF96D9D6),
  'Lucha': Color(0xFFC22E28),
  'Veneno': Color(0xFFA33EA1),
  'Tierra': Color(0xFFE2BF65),
  'Volador': Color(0xFFA98FF3),
  'Psiquico': Color(0xFFF95587),
  'Bicho': Color(0xFFA6B91A),
  'Roca': Color(0xFFB6A136),
  'Fantasma': Color(0xFF735797),
  'Dragon': Color(0xFF6F35FC),
  'Siniestro': Color(0xFF705746),
  'Acero': Color(0xFFB7B7CE),
  'Hada': Color(0xFFD685AD),
};

Color pokemonTypeColor(String type) {
  return pokemonTypeColors[type] ?? const Color(0xFF90A4AE);
}

Gradient pokemonTypeGradient(List<String> types) {
  if (types.isEmpty) {
    return const LinearGradient(colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)]);
  }

  if (types.length == 1) {
    final color = pokemonTypeColor(types.first);
    return LinearGradient(colors: [color.withValues(alpha: 0.35), color]);
  }

  return LinearGradient(
    colors: [pokemonTypeColor(types.first), pokemonTypeColor(types[1])],
  );
}
