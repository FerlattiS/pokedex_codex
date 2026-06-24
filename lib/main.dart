import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_shell.dart';
import 'services/app_settings_repository.dart';
import 'services/game_results_repository.dart';
import 'services/pokedle_progress_repository.dart';
import 'services/pokemon_questions_progress_repository.dart';
import 'services/pokemon_cache_store.dart';
import 'services/pokemon_repository.dart';
import 'services/supabase_service.dart';
import 'services/user_data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final supabaseClient = initializeSupabase();
  final appSettingsRepository = SharedPreferencesAppSettingsRepository(
    preferences,
  );
  final themeMode = await appSettingsRepository.readThemeMode();
  final pokemonCacheStore = SharedPreferencesPokemonCacheStore(preferences);

  runApp(
    MyApp(
      pokemonRepository: PokeApiPokemonRepository(
        cacheStore: pokemonCacheStore,
      ),
      pokemonCacheStore: pokemonCacheStore,
      userDataRepository: LocalUserDataRepository(preferences),
      pokedleProgressRepository: LocalPokedleProgressRepository(preferences),
      gameResultsRepository: LocalGameResultsRepository(preferences),
      pokemonQuestionsProgressRepository:
          LocalPokemonQuestionsProgressRepository(preferences),
      appSettingsRepository: appSettingsRepository,
      initialThemeMode: themeMode,
      isSupabaseConfigured: supabaseClient != null,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.pokemonRepository,
    this.userDataRepository,
    this.pokedleProgressRepository,
    this.gameResultsRepository,
    this.pokemonQuestionsProgressRepository,
    this.pokemonCacheStore,
    this.appSettingsRepository,
    this.initialThemeMode = ThemeMode.light,
    this.isSupabaseConfigured = false,
  });

  final PokemonRepository? pokemonRepository;
  final UserDataRepository? userDataRepository;
  final PokedleProgressRepository? pokedleProgressRepository;
  final GameResultsRepository? gameResultsRepository;
  final PokemonQuestionsProgressRepository? pokemonQuestionsProgressRepository;
  final PokemonCacheStore? pokemonCacheStore;
  final AppSettingsRepository? appSettingsRepository;
  final ThemeMode initialThemeMode;
  final bool isSupabaseConfigured;

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
        pokedleProgressRepository:
            widget.pokedleProgressRepository ??
            MemoryPokedleProgressRepository(),
        gameResultsRepository:
            widget.gameResultsRepository ?? MemoryGameResultsRepository(),
        pokemonQuestionsProgressRepository:
            widget.pokemonQuestionsProgressRepository ??
            MemoryPokemonQuestionsProgressRepository(),
        pokemonCacheStore: widget.pokemonCacheStore,
        isDarkMode: _themeMode == ThemeMode.dark,
        onDarkModeChanged: _setDarkMode,
        isSupabaseConfigured: widget.isSupabaseConfigured,
      ),
    );
  }
}
