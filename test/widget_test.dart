import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_codex/main.dart';
import 'package:pokedex_codex/models/pokemon_preview.dart';
import 'package:pokedex_codex/models/user_pokemon_data.dart';
import 'package:pokedex_codex/screens/pokedle_page.dart';
import 'package:pokedex_codex/services/pokedle_progress_repository.dart';
import 'package:pokedex_codex/services/pokemon_repository.dart';
import 'package:pokedex_codex/services/user_data_repository.dart';

void main() {
  final pokemonRepository = _FakePokemonRepository();

  testWidgets('Shows the full Pokedex catalog', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Pokedex Codex Pro'), findsOneWidget);
    expect(find.text('Explora el mundo Pokemon'), findsNothing);
    expect(find.text('5 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Charmander'), findsOneWidget);
    expect(find.text('Squirtle'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('Chikorita'), findsOneWidget);
    expect(find.text('Planta'), findsWidgets);
    expect(find.text('Veneno'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.view_list), findsOneWidget);
    expect(find.byIcon(Icons.grid_view), findsOneWidget);
  });

  testWidgets('Filters Pokemon by name across the loaded catalog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('pokemonSearchField')),
      'pika',
    );
    await tester.pump();

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('Filters Pokemon by selected type', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.tap(_filterChip('Agua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();

    expect(find.text('2 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Squirtle'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Wooper'), 120);
    expect(find.text('Wooper'), findsOneWidget);
    expect(find.text('Pikachu'), findsNothing);
  });

  testWidgets('Filters Pokemon by combined selected types', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.tap(_filterChip('Agua'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      _filterChip('Tierra'),
      120,
      scrollable: _filterScrollView(),
    );
    await tester.tap(_filterChip('Tierra'));
    await tester.pumpAndSettle();

    expect(find.text('1 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Wooper'), findsOneWidget);
    expect(find.text('Squirtle'), findsNothing);
  });

  testWidgets('Shows empty state when search has no results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('pokemonSearchField')),
      'mewtwo',
    );
    await tester.pump();

    expect(find.text('No hay Pokemon para mostrar'), findsOneWidget);
  });

  testWidgets('Filters Pokemon by generation', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('generationFilter-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gen 2').last);
    await tester.pumpAndSettle();

    expect(find.text('1 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Chikorita'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('Filters Pokemon by favorites only', (WidgetTester tester) async {
    final userDataRepository = MemoryUserDataRepository();
    await userDataRepository.writeFavoritePokemonIds({25});

    await tester.pumpWidget(
      MyApp(
        pokemonRepository: pokemonRepository,
        userDataRepository: userDataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Solo favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('1 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('Filters Pokemon by rarity metadata', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('rarityFilter-any')),
      120,
      scrollable: _filterScrollView(),
    );
    await tester.tap(find.byKey(const ValueKey('rarityFilter-any')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Legendario').last);
    await tester.pumpAndSettle();

    expect(find.text('1 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('Chikorita'), findsNothing);
  });

  testWidgets('Filters Pokemon by move learned by any method', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('moveSearchField')),
      120,
      scrollable: _filterScrollView(),
    );
    await tester.enterText(
      find.byKey(const ValueKey('moveSearchField')),
      'thunder',
    );
    await tester.pumpAndSettle();

    expect(find.text('1 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('Sorts Pokemon by name descending', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sortFilter-numberAsc')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nombre Z-A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();

    final squirtleTop = tester.getTopLeft(find.text('Squirtle'));
    await tester.scrollUntilVisible(find.text('Pikachu'), 120);
    final pikachuTop = tester.getTopLeft(find.text('Pikachu'));

    expect(squirtleTop.dy, lessThan(pikachuTop.dy));
  });

  testWidgets('Clears search and generation filters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('pokemonSearchField')),
      'pika',
    );
    await tester.tap(find.byKey(const ValueKey('generationFilter-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gen 2').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('clearFiltersButton')),
      120,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('filterScrollView')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('clearFiltersButton')));
    await tester.pumpAndSettle();

    expect(find.text('5 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
  });

  testWidgets('Switches between list and grid view', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsNothing);

    await tester.tap(find.byIcon(Icons.grid_view));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
  });

  testWidgets('Marks Pokemon as favorite from the Pokedex', (
    WidgetTester tester,
  ) async {
    final userDataRepository = MemoryUserDataRepository();

    await tester.pumpWidget(
      MyApp(
        pokemonRepository: pokemonRepository,
        userDataRepository: userDataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Agregar favorito').first);
    await tester.pumpAndSettle();

    expect(await userDataRepository.readFavoritePokemonIds(), contains(1));
    expect(find.byTooltip('Quitar favorito'), findsOneWidget);

    await tester.tap(find.text('Bulbasaur'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Quitar favorito'), findsOneWidget);
  });

  testWidgets('Shows the main menu options', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Pokedex'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('About us'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Daily Randommon'), findsOneWidget);
    expect(find.text('POKEDLE PRO'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(find.text('Modo oscuro'), findsOneWidget);
  });

  testWidgets('Opens favorite Pokemon from the main menu', (
    WidgetTester tester,
  ) async {
    final userDataRepository = MemoryUserDataRepository();
    await userDataRepository.writeFavoritePokemonIds({1, 7});

    await tester.pumpWidget(
      MyApp(
        pokemonRepository: pokemonRepository,
        userDataRepository: userDataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Squirtle'), findsOneWidget);
    expect(find.text('Charmander'), findsNothing);
  });

  testWidgets('Opens profile from the main menu', (WidgetTester tester) async {
    final userDataRepository = MemoryUserDataRepository();
    await userDataRepository.writeFavoritePokemonIds({1, 4});
    await userDataRepository.writeNote(
      PokemonNote(
        pokemonId: 1,
        text: 'Starter favorito.',
        updatedAt: DateTime(2026, 6, 21),
      ),
    );
    await userDataRepository.writeTeam(
      PokemonTeam(
        id: 'team-1',
        name: 'Equipo Kanto',
        pokemonIds: [1, 4, 7],
        updatedAt: DateTime(2026, 6, 21),
      ),
    );

    await tester.pumpWidget(
      MyApp(
        pokemonRepository: pokemonRepository,
        userDataRepository: userDataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Entrenador'), findsOneWidget);
    expect(find.text('Invitado'), findsOneWidget);
    expect(find.text('Modo local sin Supabase configurado'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Equipos'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
  });

  testWidgets('Opens About us and Help pages from the main menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About us'));
    await tester.pumpAndSettle();

    expect(find.text('Enfoque'), findsOneWidget);
    expect(find.text('Roadmap'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Guia rapida'), findsOneWidget);
    expect(find.text('Buscar Pokemon'), findsOneWidget);
    expect(find.text('Detalles'), findsOneWidget);
  });

  testWidgets('Opens settings from the main menu', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Preferencias'), findsOneWidget);
    expect(find.text('Supabase'), findsOneWidget);
    expect(find.text('No configurado'), findsOneWidget);
    expect(find.text('Datos locales'), findsOneWidget);
    expect(find.text('Cache de PokeAPI'), findsOneWidget);
    expect(
      find.text('Se guarda localmente en este dispositivo.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
  });

  testWidgets('Opens Daily Randommon from the main menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Randommon'));
    await tester.pumpAndSettle();

    expect(find.text('Pokemon de hoy'), findsOneWidget);
    expect(find.text('Ver detalle'), findsOneWidget);
  });

  testWidgets('Opens Daily Randommon detail page', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Randommon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver detalle'));
    await tester.pumpAndSettle();

    expect(find.text('Altura'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Habilidades'), 120);
    expect(find.text('Habilidades'), findsOneWidget);
  });

  testWidgets('Opens POKEDLE PRO from the main menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('POKEDLE PRO'));
    await tester.pumpAndSettle();

    expect(find.text('POKEDLE PRO'), findsWidgets);
    expect(find.text('Adivina el Pokemon diario'), findsOneWidget);
    expect(find.byKey(const ValueKey('pokedleGuessField')), findsOneWidget);
  });

  testWidgets('Plays Pokedle guesses for the daily Pokemon', (
    WidgetTester tester,
  ) async {
    final progressRepository = MemoryPokedleProgressRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PokedlePage(
            pokemonRepository: pokemonRepository,
            progressRepository: progressRepository,
            date: DateTime(2026, 6, 22),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavia no hay intentos'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('pokedleGuessField')),
      'char',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Charmander').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar'));
    await tester.pumpAndSettle();

    expect(find.text('Charmander'), findsOneWidget);
    expect(find.textContaining('#004'), findsNothing);
    expect(find.byIcon(Icons.catching_pokemon), findsOneWidget);
    expect(find.text('Tipo 1'), findsOneWidget);
    expect(find.text('Stat top'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('pokedleGuessField')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulbasaur').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar'));
    await tester.pumpAndSettle();

    expect(find.text('Correcto: Bulbasaur'), findsOneWidget);
    expect(await progressRepository.readGuessIds('2026-06-22'), [4, 1]);
  });

  testWidgets('Switches between light and dark mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode), findsOneWidget);

    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
  });

  testWidgets('Opens Pokemon detail page', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bulbasaur'));
    await tester.pumpAndSettle();

    expect(
      find.text('Una semilla crece en su lomo desde que nace.'),
      findsOneWidget,
    );
    expect(find.text('Altura'), findsOneWidget);
    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('Linea evolutiva'), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Nivel 16'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Habilidades'), 120);
    expect(find.text('Habilidades'), findsOneWidget);
    expect(find.text('Espesura'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Stats'), 120);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('HP'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Movimientos'), 160);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Nivel'), findsOneWidget);
    await tester.tap(find.text('Nivel'));
    await tester.pumpAndSettle();
    expect(find.text('Placaje'), findsOneWidget);
    expect(find.textContaining('Poder 40'), findsOneWidget);
    expect(find.textContaining('PP 35'), findsOneWidget);
  });

  testWidgets('Opens ability detail dialog', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bulbasaur'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Espesura'), 120);
    await tester.tap(find.text('Espesura'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre en ingles: Overgrow'), findsOneWidget);
    expect(find.text('Detalle tecnico'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
  });

  testWidgets('Opens move detail dialog', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bulbasaur'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Nivel'), 160);
    await tester.tap(find.text('Nivel'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Placaje'), 120);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Placaje'));
    await tester.pumpAndSettle();

    expect(find.text('Poder: 40'), findsOneWidget);
    expect(find.text('PP: 35'), findsOneWidget);
    expect(find.text('Precision: 100%'), findsOneWidget);
  });

  testWidgets('Shows error state when repository fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(pokemonRepository: _FailingPokemonRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar la Pokedex'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}

Finder _filterChip(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(FilterChip));
}

Finder _filterScrollView() {
  return find
      .descendant(
        of: find.byKey(const ValueKey('filterScrollView')),
        matching: find.byType(Scrollable),
      )
      .first;
}

class _FakePokemonRepository implements PokemonRepository {
  @override
  Future<List<PokemonPreview>> fetchPokemonCatalog({int limit = 1302}) async {
    return const [
      PokemonPreview(
        id: 1,
        name: 'Bulbasaur',
        types: ['Planta', 'Veneno'],
        generation: 1,
      ),
      PokemonPreview(
        id: 4,
        name: 'Charmander',
        types: ['Fuego'],
        generation: 1,
      ),
      PokemonPreview(id: 7, name: 'Squirtle', types: ['Agua'], generation: 1),
      PokemonPreview(
        id: 25,
        name: 'Pikachu',
        types: ['Electrico'],
        generation: 1,
      ),
      PokemonPreview(
        id: 152,
        name: 'Chikorita',
        types: ['Planta'],
        generation: 2,
      ),
    ];
  }

  @override
  Future<List<PokemonPreview>> fetchPokemonByTypes(
    List<String> typeNames,
  ) async {
    if (typeNames.contains('water') && typeNames.contains('ground')) {
      return const [
        PokemonPreview(id: 194, name: 'Wooper', types: ['Agua', 'Tierra']),
      ];
    }

    if (typeNames.contains('water')) {
      return const [
        PokemonPreview(id: 7, name: 'Squirtle', types: ['Agua']),
        PokemonPreview(id: 194, name: 'Wooper', types: ['Agua', 'Tierra']),
      ];
    }

    return const [];
  }

  @override
  Future<PokemonPreview> fetchPokemonDetail(int id) async {
    return _detailPokemon(id);
  }

  @override
  Future<PokemonPreview> fetchPokemonMetadata(int id) async {
    return switch (id) {
      25 => const PokemonPreview(
        id: 25,
        name: 'Pikachu',
        isLegendary: true,
        evolvesByItem: true,
        generation: 1,
        evolutionStage: PokemonEvolutionStage.middle,
      ),
      152 => const PokemonPreview(
        id: 152,
        name: 'Chikorita',
        isMythical: true,
        generation: 2,
        evolutionStage: PokemonEvolutionStage.base,
      ),
      _ => PokemonPreview(
        id: id,
        name: _pokemonName(id),
        generation: id >= 152 ? 2 : 1,
        evolutionStage: PokemonEvolutionStage.base,
      ),
    };
  }

  String _pokemonName(int id) {
    return switch (id) {
      1 => 'Bulbasaur',
      4 => 'Charmander',
      7 => 'Squirtle',
      194 => 'Wooper',
      _ => 'Pokemon $id',
    };
  }

  PokemonPreview _detailPokemon(int id) {
    return switch (id) {
      4 => const PokemonPreview(
        id: 4,
        name: 'Charmander',
        types: ['Fuego'],
        description: 'Prefiere las cosas calientes.',
        height: '0.6 m',
        weight: '8.5 kg',
        generation: 1,
        abilities: [PokemonAbility(name: 'Mar llamas', apiName: 'blaze')],
        stats: [
          PokemonStat(name: 'HP', value: 39),
          PokemonStat(name: 'Ataque', value: 52),
          PokemonStat(name: 'Defensa', value: 43),
          PokemonStat(name: 'Ataque esp.', value: 60),
          PokemonStat(name: 'Defensa esp.', value: 50),
          PokemonStat(name: 'Velocidad', value: 65),
        ],
        moves: [
          PokemonMoveSummary(
            name: 'Aranazo',
            apiName: 'scratch',
            learnMethod: 'Nivel',
            level: 1,
          ),
        ],
        evolutionStage: PokemonEvolutionStage.base,
        evolutionLine: [
          PokemonEvolutionStep(id: 4, name: 'Charmander', method: 'Base'),
          PokemonEvolutionStep(id: 5, name: 'Charmeleon', method: 'Nivel 16'),
          PokemonEvolutionStep(id: 6, name: 'Charizard', method: 'Nivel 36'),
        ],
      ),
      25 => const PokemonPreview(
        id: 25,
        name: 'Pikachu',
        types: ['Electrico'],
        description: 'Puede soltar descargas electricas.',
        height: '0.4 m',
        weight: '6.0 kg',
        isLegendary: true,
        evolvesByItem: true,
        generation: 1,
        evolutionStage: PokemonEvolutionStage.middle,
        stats: [
          PokemonStat(name: 'HP', value: 35),
          PokemonStat(name: 'Ataque', value: 55),
          PokemonStat(name: 'Defensa', value: 40),
          PokemonStat(name: 'Ataque esp.', value: 50),
          PokemonStat(name: 'Defensa esp.', value: 50),
          PokemonStat(name: 'Velocidad', value: 90),
        ],
        moves: [
          PokemonMoveSummary(
            name: 'Impactrueno',
            apiName: 'thunder-shock',
            learnMethod: 'Nivel',
            level: 1,
          ),
        ],
        evolutionLine: [
          PokemonEvolutionStep(id: 172, name: 'Pichu', method: 'Base'),
          PokemonEvolutionStep(id: 25, name: 'Pikachu', method: 'Amistad alta'),
          PokemonEvolutionStep(
            id: 26,
            name: 'Raichu',
            method: 'Usar Thunder stone',
          ),
        ],
      ),
      _ => const PokemonPreview(
        id: 1,
        name: 'Bulbasaur',
        types: ['Planta', 'Veneno'],
        description: 'Una semilla crece en su lomo desde que nace.',
        height: '0.7 m',
        weight: '6.9 kg',
        generation: 1,
        abilities: [PokemonAbility(name: 'Espesura', apiName: 'overgrow')],
        stats: [
          PokemonStat(name: 'HP', value: 45),
          PokemonStat(name: 'Ataque', value: 49),
          PokemonStat(name: 'Defensa', value: 49),
          PokemonStat(name: 'Ataque esp.', value: 65),
          PokemonStat(name: 'Defensa esp.', value: 65),
          PokemonStat(name: 'Velocidad', value: 45),
        ],
        moves: [
          PokemonMoveSummary(
            name: 'Placaje',
            apiName: 'tackle',
            learnMethod: 'Nivel',
            level: 1,
          ),
        ],
        evolutionStage: PokemonEvolutionStage.base,
        evolutionLine: [
          PokemonEvolutionStep(id: 1, name: 'Bulbasaur', method: 'Base'),
          PokemonEvolutionStep(id: 2, name: 'Ivysaur', method: 'Nivel 16'),
          PokemonEvolutionStep(id: 3, name: 'Venusaur', method: 'Nivel 32'),
        ],
      ),
    };
  }

  @override
  Future<PokemonAbilityDetail> fetchAbilityDetail(String abilityName) async {
    return const PokemonAbilityDetail(
      name: 'Espesura',
      englishName: 'Overgrow',
      description: 'Potencia los movimientos de tipo Planta.',
      englishDescription: 'Powers up Grass-type moves.',
      technicalDetail:
          'When HP is low, Grass-type moves are powered up by 50%.',
    );
  }

  @override
  Future<PokemonMoveDetail> fetchMoveDetail(String moveName) async {
    return const PokemonMoveDetail(
      name: 'Placaje',
      englishName: 'Tackle',
      type: 'Normal',
      damageClass: 'Physical',
      power: 40,
      pp: 35,
      accuracy: 100,
      description: 'Embiste al objetivo.',
      technicalDetail: 'Inflicts regular damage.',
    );
  }
}

class _FailingPokemonRepository implements PokemonRepository {
  @override
  Future<List<PokemonPreview>> fetchPokemonCatalog({int limit = 1302}) async {
    throw Exception('Test error');
  }

  @override
  Future<List<PokemonPreview>> fetchPokemonByTypes(
    List<String> typeNames,
  ) async {
    throw Exception('Test error');
  }

  @override
  Future<PokemonPreview> fetchPokemonDetail(int id) async {
    throw Exception('Test error');
  }

  @override
  Future<PokemonPreview> fetchPokemonMetadata(int id) async {
    throw Exception('Test error');
  }

  @override
  Future<PokemonAbilityDetail> fetchAbilityDetail(String abilityName) async {
    throw Exception('Test error');
  }

  @override
  Future<PokemonMoveDetail> fetchMoveDetail(String moveName) async {
    throw Exception('Test error');
  }
}
