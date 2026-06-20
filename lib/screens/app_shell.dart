import 'package:flutter/material.dart';

import '../services/pokemon_repository.dart';
import 'daily_randommon_page.dart';
import 'pokedex_home_page.dart';
import 'placeholder_page.dart';

enum MainMenuDestination {
  pokedex,
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
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final PokemonRepository pokemonRepository;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

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
        ),
        MainMenuDestination.aboutUs => const PlaceholderPage(
          title: 'About us',
          message: 'Informacion del proyecto disponible mas adelante.',
        ),
        MainMenuDestination.help => const PlaceholderPage(
          title: 'Help',
          message: 'Guia de uso disponible mas adelante.',
        ),
        MainMenuDestination.settings => const PlaceholderPage(
          title: 'Settings',
          message: 'Configuracion avanzada disponible mas adelante.',
        ),
        MainMenuDestination.dailyRandommon => DailyRandommonPage(
          pokemonRepository: widget.pokemonRepository,
        ),
        MainMenuDestination.pokedlePro => const PlaceholderPage(
          title: 'POKEDLE PRO',
          message: 'Proyecto disponible mas adelante.',
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
      MainMenuDestination.aboutUs => 'About us',
      MainMenuDestination.help => 'Help',
      MainMenuDestination.settings => 'Settings',
      MainMenuDestination.dailyRandommon => 'Daily Randommon',
      MainMenuDestination.pokedlePro => 'POKEDLE PRO',
      MainMenuDestination.quit => 'Quit',
    };
  }
}
