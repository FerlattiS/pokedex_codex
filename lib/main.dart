import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_shell.dart';
import 'services/app_settings_repository.dart';
import 'services/pokemon_cache_store.dart';
import 'services/pokemon_repository.dart';
import 'services/user_data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final appSettingsRepository = SharedPreferencesAppSettingsRepository(
    preferences,
  );
  final themeMode = await appSettingsRepository.readThemeMode();

  runApp(
    MyApp(
      pokemonRepository: PokeApiPokemonRepository(
        cacheStore: SharedPreferencesPokemonCacheStore(preferences),
      ),
      userDataRepository: LocalUserDataRepository(preferences),
      appSettingsRepository: appSettingsRepository,
      initialThemeMode: themeMode,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.pokemonRepository,
    this.userDataRepository,
    this.appSettingsRepository,
    this.initialThemeMode = ThemeMode.light,
  });

  final PokemonRepository? pokemonRepository;
  final UserDataRepository? userDataRepository;
  final AppSettingsRepository? appSettingsRepository;
  final ThemeMode initialThemeMode;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late var _themeMode = widget.initialThemeMode;

  void _setDarkMode(bool isDarkMode) {
    final nextThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    setState(() {
      _themeMode = nextThemeMode;
    });

    final appSettingsRepository = widget.appSettingsRepository;
    if (appSettingsRepository != null) {
      unawaited(appSettingsRepository.writeThemeMode(nextThemeMode));
    }
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
        userDataRepository:
            widget.userDataRepository ?? MemoryUserDataRepository(),
        isDarkMode: _themeMode == ThemeMode.dark,
        onDarkModeChanged: _setDarkMode,
      ),
    );
  }
}
