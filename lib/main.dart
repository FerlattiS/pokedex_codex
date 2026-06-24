import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'navigation/app_router.dart';
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
  late final PokemonRepository _pokemonRepository;
  late final UserDataRepository _userDataRepository;
  late final PokedleProgressRepository _pokedleProgressRepository;
  late final GameResultsRepository _gameResultsRepository;
  late final PokemonQuestionsProgressRepository
  _pokemonQuestionsProgressRepository;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _pokemonRepository = widget.pokemonRepository ?? PokeApiPokemonRepository();
    _userDataRepository =
        widget.userDataRepository ?? MemoryUserDataRepository();
    _pokedleProgressRepository =
        widget.pokedleProgressRepository ?? MemoryPokedleProgressRepository();
    _gameResultsRepository =
        widget.gameResultsRepository ?? MemoryGameResultsRepository();
    _pokemonQuestionsProgressRepository =
        widget.pokemonQuestionsProgressRepository ??
        MemoryPokemonQuestionsProgressRepository();
    _router = createAppRouter(
      shellBuilder: (context, destination) {
        return AppShell(
          pokemonRepository: _pokemonRepository,
          userDataRepository: _userDataRepository,
          pokedleProgressRepository: _pokedleProgressRepository,
          gameResultsRepository: _gameResultsRepository,
          pokemonQuestionsProgressRepository:
              _pokemonQuestionsProgressRepository,
          pokemonCacheStore: widget.pokemonCacheStore,
          onDarkModeChanged: _setDarkMode,
          isSupabaseConfigured: widget.isSupabaseConfigured,
          selectedDestination: destination,
          onDestinationSelected: (nextDestination) {
            context.go(nextDestination.path);
          },
        );
      },
    );
  }

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
    return MaterialApp.router(
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
      routerConfig: _router,
    );
  }
}
