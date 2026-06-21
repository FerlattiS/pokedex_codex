import 'package:flutter/material.dart';

import '../services/pokemon_repository.dart';
import '../services/pokedle_progress_repository.dart';
import '../services/user_data_repository.dart';
import 'about_us_page.dart';
import 'daily_randommon_page.dart';
import 'favorites_page.dart';
import 'help_page.dart';
import 'pokedex_home_page.dart';
import 'pokedle_page.dart';
import 'placeholder_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

enum MainMenuDestination {
  pokedex,
  favorites,
  profile,
  aboutUs,
  help,
  settings,
  dailyRandommon,
  pokedlePro,
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
  var _destination = MainMenuDestination.pokedex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(_destination.title)),
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
        MainMenuDestination.quit => const PlaceholderPage(
          title: 'Quit',
          message: 'Salida de la app disponible mas adelante.',
        ),
      },
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
      MainMenuDestination.pokedex => 'Pokedex Codex Pro',
      MainMenuDestination.favorites => 'Favoritos',
      MainMenuDestination.profile => 'Perfil',
      MainMenuDestination.aboutUs => 'About us',
      MainMenuDestination.help => 'Help',
      MainMenuDestination.settings => 'Settings',
      MainMenuDestination.dailyRandommon => 'Daily Randommon',
      MainMenuDestination.pokedlePro => 'POKEDLE PRO',
      MainMenuDestination.quit => 'Quit',
    };
  }
}
