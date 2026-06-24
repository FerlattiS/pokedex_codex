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
  quit;

  String get path {
    return switch (this) {
      MainMenuDestination.home => '/',
      MainMenuDestination.pokedex => '/pokedex',
      MainMenuDestination.favorites => '/favorites',
      MainMenuDestination.profile => '/profile',
      MainMenuDestination.aboutUs => '/about',
      MainMenuDestination.help => '/help',
      MainMenuDestination.settings => '/settings',
      MainMenuDestination.games => '/games',
      MainMenuDestination.dailyRandommon => '/daily-randommon',
      MainMenuDestination.pokedlePro => '/games/pokedle',
      MainMenuDestination.higherOrLower => '/games/higher-or-lower',
      MainMenuDestination.pokemonQuestions => '/games/15-preguntas',
      MainMenuDestination.quit => '/quit',
    };
  }

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
