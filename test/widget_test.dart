import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_codex/main.dart';
import 'package:pokedex_codex/models/pokemon_preview.dart';
import 'package:pokedex_codex/services/pokemon_repository.dart';

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
    await tester.enterText(find.byType(TextField), 'pika');
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

    expect(find.text('2 Pokemon encontrados'), findsOneWidget);
    expect(find.text('Squirtle'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField), 'mewtwo');
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

  testWidgets('Sorts Pokemon by name descending', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busqueda y filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sortFilter-numberAsc')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nombre Z-A').last);
    await tester.pumpAndSettle();

    final squirtleTop = tester.getTopLeft(find.text('Squirtle'));
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

  testWidgets('Shows the main menu options', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Pokedex'), findsOneWidget);
    expect(find.text('About us'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Daily Randommon'), findsOneWidget);
    expect(find.text('POKEDLE PRO'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(find.text('Modo oscuro'), findsOneWidget);
  });

  testWidgets('Opens placeholder pages from the main menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About us'));
    await tester.pumpAndSettle();

    expect(
      find.text('Informacion del proyecto disponible mas adelante.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Guia de uso disponible mas adelante.'), findsOneWidget);
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
    expect(find.text('Habilidades'), findsOneWidget);
  });

  testWidgets('Switches between light and dark mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(pokemonRepository: pokemonRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode), findsOneWidget);

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
    expect(find.text('Habilidades'), findsOneWidget);
    expect(find.text('Espesura'), findsOneWidget);
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

class _FakePokemonRepository implements PokemonRepository {
  @override
  Future<List<PokemonPreview>> fetchPokemonCatalog({int limit = 1302}) async {
    return const [
      PokemonPreview(id: 1, name: 'Bulbasaur', types: ['Planta', 'Veneno']),
      PokemonPreview(id: 4, name: 'Charmander', types: ['Fuego']),
      PokemonPreview(id: 7, name: 'Squirtle', types: ['Agua']),
      PokemonPreview(id: 25, name: 'Pikachu', types: ['Electrico']),
      PokemonPreview(id: 152, name: 'Chikorita', types: ['Planta']),
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
    return const PokemonPreview(
      id: 1,
      name: 'Bulbasaur',
      types: ['Planta', 'Veneno'],
      description: 'Una semilla crece en su lomo desde que nace.',
      height: '0.7 m',
      weight: '6.9 kg',
      abilities: [PokemonAbility(name: 'Espesura', apiName: 'overgrow')],
      stats: [
        PokemonStat(name: 'HP', value: 45),
        PokemonStat(name: 'Ataque', value: 49),
      ],
      moves: [
        PokemonMoveSummary(
          name: 'Placaje',
          apiName: 'tackle',
          learnMethod: 'Nivel',
          level: 1,
        ),
      ],
    );
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
  Future<PokemonAbilityDetail> fetchAbilityDetail(String abilityName) async {
    throw Exception('Test error');
  }

  @override
  Future<PokemonMoveDetail> fetchMoveDetail(String moveName) async {
    throw Exception('Test error');
  }
}
