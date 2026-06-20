import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_codex/services/pokemon_repository.dart';

void main() {
  test('Fetches the full Pokemon catalog from PokeAPI responses', () async {
    final repository = PokeApiPokemonRepository(
      client: MockClient((request) async {
        return http.Response('''
          {
            "results": [
              {
                "name": "bulbasaur",
                "url": "https://pokeapi.co/api/v2/pokemon/1/"
              }
            ]
          }
          ''', 200);
      }),
    );

    final pokemon = await repository.fetchPokemonCatalog();

    expect(pokemon, hasLength(1));
    expect(pokemon.first.id, 1);
    expect(pokemon.first.name, 'Bulbasaur');
    expect(pokemon.first.types, isEmpty);
  });

  test('Fetches Pokemon by combined types', () async {
    final repository = PokeApiPokemonRepository(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/type/water')) {
          return http.Response(
            _typeResponse(['squirtle', 'wooper'], [7, 194]),
            200,
          );
        }

        return http.Response(
          _typeResponse(['sandshrew', 'wooper'], [27, 194]),
          200,
        );
      }),
    );

    final pokemon = await repository.fetchPokemonByTypes(['water', 'ground']);

    expect(pokemon, hasLength(1));
    expect(pokemon.first.id, 194);
    expect(pokemon.first.name, 'Wooper');
    expect(pokemon.first.types, ['Agua', 'Tierra']);
  });

  test('Fetches Pokemon detail from PokeAPI responses', () async {
    final repository = PokeApiPokemonRepository(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/pokemon-species/1')) {
          return http.Response('''
            {
              "flavor_text_entries": [
                {
                  "flavor_text": "Una rara semilla fue plantada en su lomo al nacer.",
                  "language": {
                    "name": "es"
                  }
                }
              ]
            }
            ''', 200);
        }

        return http.Response('''
          {
            "id": 1,
            "name": "bulbasaur",
            "height": 7,
            "weight": 69,
            "abilities": [
              {
                "ability": {
                  "name": "overgrow"
                }
              }
            ],
            "moves": [
              {
                "move": {
                  "name": "tackle"
                },
                "version_group_details": [
                  {
                    "level_learned_at": 1,
                    "move_learn_method": {
                      "name": "level-up"
                    }
                  }
                ]
              }
            ],
            "stats": [
              {
                "base_stat": 45,
                "stat": {
                  "name": "hp"
                }
              },
              {
                "base_stat": 49,
                "stat": {
                  "name": "attack"
                }
              }
            ],
            "types": [
              {
                "type": {
                  "name": "grass"
                }
              }
            ],
            "sprites": {
              "front_default": "https://example.com/bulbasaur.png",
              "other": {
                "official-artwork": {
                  "front_default": "https://example.com/art.png"
                }
              }
            }
          }
          ''', 200);
      }),
    );

    final pokemon = await repository.fetchPokemonDetail(1);

    expect(pokemon.id, 1);
    expect(pokemon.name, 'Bulbasaur');
    expect(pokemon.types, ['Planta']);
    expect(
      pokemon.description,
      'Una rara semilla fue plantada en su lomo al nacer.',
    );
    expect(pokemon.height, '0.7 m');
    expect(pokemon.weight, '6.9 kg');
    expect(pokemon.imageUrl, 'https://example.com/art.png');
    expect(pokemon.abilities.first.name, 'Overgrow');
    expect(pokemon.abilities.first.apiName, 'overgrow');
    expect(pokemon.moves.first.name, 'Tackle');
    expect(pokemon.moves.first.learnMethod, 'Nivel');
    expect(pokemon.moves.first.level, 1);
    expect(pokemon.stats.first.name, 'HP');
    expect(pokemon.stats.first.value, 45);
  });

  test('Fetches ability detail from PokeAPI responses', () async {
    final repository = PokeApiPokemonRepository(
      client: MockClient((request) async {
        return http.Response('''
          {
            "names": [
              {
                "name": "Espesura",
                "language": {
                  "name": "es"
                }
              },
              {
                "name": "Overgrow",
                "language": {
                  "name": "en"
                }
              }
            ],
            "flavor_text_entries": [
              {
                "flavor_text": "Potencia los movimientos de tipo Planta.",
                "language": {
                  "name": "es"
                }
              },
              {
                "flavor_text": "Powers up Grass-type moves.",
                "language": {
                  "name": "en"
                }
              }
            ],
            "effect_entries": [
              {
                "effect": "When HP is low, Grass-type moves are powered up by 50%.",
                "language": {
                  "name": "en"
                }
              }
            ]
          }
          ''', 200);
      }),
    );

    final ability = await repository.fetchAbilityDetail('overgrow');

    expect(ability.name, 'Espesura');
    expect(ability.englishName, 'Overgrow');
    expect(ability.description, 'Potencia los movimientos de tipo Planta.');
    expect(ability.technicalDetail, contains('50%'));
  });

  test('Fetches move detail from PokeAPI responses', () async {
    final repository = PokeApiPokemonRepository(
      client: MockClient((request) async {
        return http.Response('''
          {
            "power": 40,
            "pp": 35,
            "accuracy": 100,
            "type": {
              "name": "normal"
            },
            "damage_class": {
              "name": "physical"
            },
            "names": [
              {
                "name": "Placaje",
                "language": {
                  "name": "es"
                }
              },
              {
                "name": "Tackle",
                "language": {
                  "name": "en"
                }
              }
            ],
            "flavor_text_entries": [
              {
                "flavor_text": "Embiste al objetivo.",
                "language": {
                  "name": "es"
                }
              }
            ],
            "effect_entries": [
              {
                "effect": "Inflicts regular damage.",
                "language": {
                  "name": "en"
                }
              }
            ]
          }
          ''', 200);
      }),
    );

    final move = await repository.fetchMoveDetail('tackle');

    expect(move.name, 'Placaje');
    expect(move.englishName, 'Tackle');
    expect(move.power, 40);
    expect(move.pp, 35);
    expect(move.accuracy, 100);
    expect(move.type, 'Normal');
  });

  test('Throws when PokeAPI catalog fails', () async {
    final repository = PokeApiPokemonRepository(
      client: MockClient((request) async {
        return http.Response('{}', 500);
      }),
    );

    expect(repository.fetchPokemonCatalog(), throwsException);
  });
}

String _typeResponse(List<String> names, List<int> ids) {
  final pokemon = [
    for (var index = 0; index < names.length; index++)
      '''
      {
        "pokemon": {
          "name": "${names[index]}",
          "url": "https://pokeapi.co/api/v2/pokemon/${ids[index]}/"
        }
      }
      ''',
  ].join(',');

  return '{"pokemon": [$pokemon]}';
}
