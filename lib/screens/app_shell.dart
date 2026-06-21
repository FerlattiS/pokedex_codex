import 'package:flutter/material.dart';

import '../services/pokemon_repository.dart';
import '../services/pokedle_progress_repository.dart';
import '../services/user_data_repository.dart';
import 'about_us_page.dart';
import 'daily_randommon_page.dart';
import 'favorites_page.dart';
import 'help_page.dart';
import 'higher_or_lower_page.dart';
import 'pokedex_home_page.dart';
import 'pokedle_page.dart';
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
  dailyRandommon,
  pokedlePro,
  higherOrLower,
  quit,
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.pokemonRepository,
    required this.userDataRepository,
    required this.pokedleProgressRepository,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.isSupabaseConfigured,
  });

  final PokemonRepository pokemonRepository;
  final UserDataRepository userDataRepository;
  final PokedleProgressRepository pokedleProgressRepository;
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
          isSupabaseConfigured: widget.isSupabaseConfigured,
        ),
        MainMenuDestination.aboutUs => const AboutUsPage(),
        MainMenuDestination.help => const HelpPage(),
        MainMenuDestination.settings => SettingsPage(
          isDarkMode: widget.isDarkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
          isSupabaseConfigured: widget.isSupabaseConfigured,
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
        destination: MainMenuDestination.pokedex,
      ),
      _HomeDestination(
        title: 'POKEDLE PRO',
        subtitle: 'Adivinar el Pokemon diario',
        icon: Icons.grid_view,
        destination: MainMenuDestination.pokedlePro,
      ),
      _HomeDestination(
        title: 'Higher or Lower',
        subtitle: 'Adivinar quien tiene mas battle stats total',
        icon: Icons.trending_up,
        destination: MainMenuDestination.higherOrLower,
      ),
      _HomeDestination(
        title: 'Daily Randommon',
        subtitle: 'Pokemon aleatorio del dia',
        icon: Icons.today_outlined,
        destination: MainMenuDestination.dailyRandommon,
      ),
      _HomeDestination(
        title: 'Perfil',
        subtitle: 'Resumen, favoritos y estadisticas',
        icon: Icons.person_outline,
        destination: MainMenuDestination.profile,
      ),
      _HomeDestination(
        title: 'Favoritos',
        subtitle: 'Ver Pokemon guardados',
        icon: Icons.star_outline,
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
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final item = destinations[index];
            return Card(
              child: InkWell(
                onTap: () => onDestinationSelected(item.destination),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, size: 30),
                      const Spacer(),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
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
    required this.destination,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final MainMenuDestination destination;
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
      MainMenuDestination.dailyRandommon => 'Daily Randommon',
      MainMenuDestination.pokedlePro => 'POKEDLE PRO',
      MainMenuDestination.higherOrLower => 'Higher or Lower',
      MainMenuDestination.quit => 'Quit',
    };
  }
}
