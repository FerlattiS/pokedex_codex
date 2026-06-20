import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'services/pokemon_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.pokemonRepository});

  final PokemonRepository? pokemonRepository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _themeMode = ThemeMode.light;

  void _setDarkMode(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokedex Codex Pro',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AppShell(
        pokemonRepository:
            widget.pokemonRepository ?? PokeApiPokemonRepository(),
        isDarkMode: _themeMode == ThemeMode.dark,
        onDarkModeChanged: _setDarkMode,
      ),
    );
  }
}
