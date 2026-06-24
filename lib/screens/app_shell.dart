import 'package:flutter/material.dart';

import '../services/game_results_repository.dart';
import '../services/pokemon_repository.dart';
import '../services/pokedle_progress_repository.dart';
import '../services/pokemon_questions_progress_repository.dart';
import '../services/pokemon_cache_store.dart';
import '../services/user_data_repository.dart';
import 'about_us_page.dart';
import 'daily_randommon_page.dart';
import 'favorites_page.dart';
import 'help_page.dart';
import 'higher_or_lower_page.dart';
import 'pokedex_home_page.dart';
import 'pokedle_page.dart';
import 'pokemon_questions_page.dart';
import 'placeholder_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

enum MainMenuDestination {
  home,
  pokedex,
  favorites,
  profile,
  aboutUs,
  help,
  settings,
  games,
  dailyRandommon,
  pokedlePro,
  higherOrLower,
  pokemonQuestions,
  quit,
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.pokemonRepository,
    required this.userDataRepository,
    required this.pokedleProgressRepository,
    required this.gameResultsRepository,
    required this.pokemonQuestionsProgressRepository,
    this.pokemonCacheStore,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.isSupabaseConfigured,
  });

  final PokemonRepository pokemonRepository;
  final UserDataRepository userDataRepository;
  final PokedleProgressRepository pokedleProgressRepository;
  final GameResultsRepository gameResultsRepository;
  final PokemonQuestionsProgressRepository pokemonQuestionsProgressRepository;
  final PokemonCacheStore? pokemonCacheStore;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final bool isSupabaseConfigured;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _destination = MainMenuDestination.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _destination == MainMenuDestination.pokedlePro
            ? const _PokedleAppBarTitle()
            : Text(_destination.title),
      ),
      drawer: _MainMenuDrawer(
        selectedDestination: _destination,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onDestinationSelected: (destination) {
          setState(() {
            _destination = destination;
          });
        },
      ),
      body: switch (_destination) {
        MainMenuDestination.home => _MainMenuHomePage(
          onDestinationSelected: (destination) {
            setState(() {
              _destination = destination;
            });
          },
        ),
        MainMenuDestination.pokedex => PokedexHomePage(
          pokemonRepository: widget.pokemonRepository,
          userDataRepository: widget.userDataRepository,
        ),
        MainMenuDestination.favorites => FavoritesPage(
          pokemonRepository: widget.pokemonRepository,
          userDataRepository: widget.userDataRepository,
        ),
        MainMenuDestination.profile => ProfilePage(
          userDataRepository: widget.userDataRepository,
          pokedleProgressRepository: widget.pokedleProgressRepository,
          gameResultsRepository: widget.gameResultsRepository,
          isSupabaseConfigured: widget.isSupabaseConfigured,
        ),
        MainMenuDestination.aboutUs => const AboutUsPage(),
        MainMenuDestination.help => const HelpPage(),
        MainMenuDestination.settings => SettingsPage(
          isDarkMode: widget.isDarkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
          isSupabaseConfigured: widget.isSupabaseConfigured,
          pokemonCacheStore: widget.pokemonCacheStore,
          onClearPokemonCache: widget.pokemonRepository.clearCache,
        ),
        MainMenuDestination.games => _GamesHomePage(
          onDestinationSelected: (destination) {
            setState(() {
              _destination = destination;
            });
          },
        ),
        MainMenuDestination.dailyRandommon => DailyRandommonPage(
          pokemonRepository: widget.pokemonRepository,
          userDataRepository: widget.userDataRepository,
        ),
        MainMenuDestination.pokedlePro => PokedlePage(
          pokemonRepository: widget.pokemonRepository,
          progressRepository: widget.pokedleProgressRepository,
        ),
        MainMenuDestination.higherOrLower => HigherOrLowerPage(
          pokemonRepository: widget.pokemonRepository,
          gameResultsRepository: widget.gameResultsRepository,
        ),
        MainMenuDestination.pokemonQuestions => PokemonQuestionsPage(
          pokemonRepository: widget.pokemonRepository,
          progressRepository: widget.pokemonQuestionsProgressRepository,
          gameResultsRepository: widget.gameResultsRepository,
        ),
        MainMenuDestination.quit => const PlaceholderPage(
          title: 'Quit',
          message: 'Salida de la app disponible mas adelante.',
        ),
      },
    );
  }
}

class _MainMenuHomePage extends StatelessWidget {
  const _MainMenuHomePage({required this.onDestinationSelected});

  final ValueChanged<MainMenuDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _HomeDestination(
        title: 'Pokedex',
        subtitle: 'Explorar catalogo, filtros y detalles',
        icon: Icons.catching_pokemon,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png',
        accentColor: Color(0xFF2E7D32),
        destination: MainMenuDestination.pokedex,
      ),
      _HomeDestination(
        title: 'Juegos',
        subtitle: 'Todos los minijuegos en un solo lugar',
        icon: Icons.sports_esports_outlined,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/151.png',
        accentColor: Color(0xFFAD1457),
        destination: MainMenuDestination.games,
      ),
      _HomeDestination(
        title: 'POKEDLE PRO',
        subtitle: 'Adivinar el Pokemon diario',
        icon: Icons.grid_view,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/10088.png',
        accentColor: Color(0xFFC2185B),
        destination: MainMenuDestination.pokedlePro,
      ),
      _HomeDestination(
        title: 'Higher or Lower',
        subtitle: 'Adivinar quien tiene mas battle stats total',
        icon: Icons.trending_up,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/150.png',
        accentColor: Color(0xFF5E35B1),
        destination: MainMenuDestination.higherOrLower,
      ),
      _HomeDestination(
        title: '15 Preguntas',
        subtitle: 'Preguntas si/no y 3 intentos diarios',
        icon: Icons.psychology_alt_outlined,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/54.png',
        accentColor: Color(0xFF1565C0),
        destination: MainMenuDestination.pokemonQuestions,
      ),
      _HomeDestination(
        title: 'Daily Randommon',
        subtitle: 'Pokemon aleatorio del dia',
        icon: Icons.today_outlined,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/133.png',
        accentColor: Color(0xFFEF6C00),
        destination: MainMenuDestination.dailyRandommon,
      ),
      _HomeDestination(
        title: 'Perfil',
        subtitle: 'Resumen, favoritos y estadisticas',
        icon: Icons.person_outline,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
        accentColor: Color(0xFFF9A825),
        destination: MainMenuDestination.profile,
      ),
      _HomeDestination(
        title: 'Favoritos',
        subtitle: 'Ver Pokemon guardados',
        icon: Icons.star_outline,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/175.png',
        accentColor: Color(0xFF00838F),
        destination: MainMenuDestination.favorites,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Pokedex Codex Pro',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text('Elegi por donde empezar', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: destinations.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final item = destinations[index];
            return _HomeDestinationCard(
              item: item,
              onTap: () => onDestinationSelected(item.destination),
            );
          },
        ),
      ],
    );
  }
}

class _HomeDestination {
  const _HomeDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.spriteUrl,
    required this.accentColor,
    required this.destination,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String spriteUrl;
  final Color accentColor;
  final MainMenuDestination destination;
}

class _HomeDestinationCard extends StatelessWidget {
  const _HomeDestinationCard({required this.item, required this.onTap});

  final _HomeDestination item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.08),
                  border: Border(
                    left: BorderSide(color: item.accentColor, width: 5),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: 8,
              bottom: 4,
              child: Opacity(
                opacity: 0.26,
                child: Image.network(
                  item.spriteUrl,
                  width: 118,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.accentColor, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedleAppBarTitle extends StatelessWidget {
  const _PokedleAppBarTitle();

  static const _megaLopunnySpriteUrl =
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/10088.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.catching_pokemon, size: 22),
        const SizedBox(width: 8),
        const Text('POKEDLE PRO'),
        const SizedBox(width: 8),
        Image.network(
          _megaLopunnySpriteUrl,
          width: 34,
          height: 34,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.auto_awesome, size: 22);
          },
        ),
      ],
    );
  }
}

class _GamesHomePage extends StatelessWidget {
  const _GamesHomePage({required this.onDestinationSelected});

  final ValueChanged<MainMenuDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final games = [
      _HomeDestination(
        title: 'POKEDLE PRO',
        subtitle: 'Adivinar el Pokemon diario por pistas',
        icon: Icons.grid_view,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/10088.png',
        accentColor: Color(0xFFC2185B),
        destination: MainMenuDestination.pokedlePro,
      ),
      _HomeDestination(
        title: 'Higher or Lower',
        subtitle: 'Rachas comparando stats',
        icon: Icons.trending_up,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/150.png',
        accentColor: Color(0xFF5E35B1),
        destination: MainMenuDestination.higherOrLower,
      ),
      _HomeDestination(
        title: '15 Preguntas',
        subtitle: 'Preguntas si/no y 3 intentos diarios',
        icon: Icons.psychology_alt_outlined,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/54.png',
        accentColor: Color(0xFF1565C0),
        destination: MainMenuDestination.pokemonQuestions,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Juegos',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text('Elegí un desafio Pokemon', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: games.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final item = games[index];
            return _HomeDestinationCard(
              item: item,
              onTap: () => onDestinationSelected(item.destination),
            );
          },
        ),
      ],
    );
  }
}

class _MainMenuDrawer extends StatelessWidget {
  const _MainMenuDrawer({
    required this.selectedDestination,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onDestinationSelected,
  });

  final MainMenuDestination selectedDestination;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<MainMenuDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selectedDestination.index,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        onDestinationSelected(MainMenuDestination.values[index]);
      },
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 24, 16, 12),
          child: Text('Pokedex Codex Pro'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          label: Text('Menu'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.catching_pokemon),
          label: Text('Pokedex'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.star_outline),
          label: Text('Favoritos'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.person_outline),
          label: Text('Perfil'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.info_outline),
          label: Text('About us'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.help_outline),
          label: Text('Help'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          label: Text('Settings'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.sports_esports_outlined),
          label: Text('Juegos'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.today_outlined),
          label: Text('Daily Randommon'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.sports_esports_outlined),
          label: Text('POKEDLE PRO'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.trending_up),
          label: Text('Higher or Lower'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.psychology_alt_outlined),
          label: Text('15 Preguntas'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.exit_to_app),
          label: Text('Quit'),
        ),
        const Divider(),
        SwitchListTile(
          secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
          title: const Text('Modo oscuro'),
          value: isDarkMode,
          onChanged: onDarkModeChanged,
        ),
      ],
    );
  }
}

extension on MainMenuDestination {
  String get title {
    return switch (this) {
      MainMenuDestination.home => 'Menu',
      MainMenuDestination.pokedex => 'Pokedex Codex Pro',
      MainMenuDestination.favorites => 'Favoritos',
      MainMenuDestination.profile => 'Perfil',
      MainMenuDestination.aboutUs => 'About us',
      MainMenuDestination.help => 'Help',
      MainMenuDestination.settings => 'Settings',
      MainMenuDestination.games => 'Juegos',
      MainMenuDestination.dailyRandommon => 'Daily Randommon',
      MainMenuDestination.pokedlePro => 'POKEDLE PRO',
      MainMenuDestination.higherOrLower => 'Higher or Lower',
      MainMenuDestination.pokemonQuestions => '15 Preguntas',
      MainMenuDestination.quit => 'Quit',
    };
  }
}
