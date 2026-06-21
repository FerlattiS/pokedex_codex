import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_codex/models/pokemon_preview.dart';
import 'package:pokedex_codex/services/pokemon_cache_store.dart';
import 'package:pokedex_codex/services/pokemon_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        if (request.url.path.contains('/pokemon-species/1')) {
          return http.Response('''
            {
              "color": {
                "name": "green"
              },
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
            "species": {
              "url": "https://pokeapi.co/api/v2/pokemon-species/1/"
            },
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
              "back_default": "https://example.com/bulbasaur-back.png",
              "front_shiny": "https://example.com/bulbasaur-shiny.png",
              "back_shiny": "https://example.com/bulbasaur-back-shiny.png",
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
    expect(pokemon.frontSpriteUrl, 'https://example.com/bulbasaur.png');
    expect(pokemon.backSpriteUrl, 'https://example.com/bulbasaur-back.png');
    expect(
      pokemon.frontShinySpriteUrl,
      'https://example.com/bulbasaur-shiny.png',
    );
    expect(
      pokemon.backShinySpriteUrl,
      'https://example.com/bulbasaur-back-shiny.png',
    );
    expect(pokemon.generation, 1);
    expect(pokemon.speciesColor, 'Verde');
    expect(pokemon.formLabel, 'Normal');
    expect(pokemon.abilities.first.name, 'Overgrow');
    expect(pokemon.abilities.first.apiName, 'overgrow');
    expect(pokemon.moves.first.name, 'Tackle');
    expect(pokemon.moves.first.learnMethod, 'Nivel');
    expect(pokemon.moves.first.level, 1);
    expect(pokemon.stats.first.name, 'HP');
    expect(pokemon.stats.first.value, 45);
  });

  test('Fetches alternative form detail from base species metadata', () async {
    final repository = PokeApiPokemonRepository(
      client: MockClient((request) async {
        if (request.url.path.contains('/pokemon/10106')) {
          return http.Response('''
            {
              "id": 10106,
              "name": "dugtrio-alola",
              "species": {
                "url": "https://pokeapi.co/api/v2/pokemon-species/51/"
              },
              "height": 7,
              "weight": 666,
              "abilities": [],
              "moves": [],
              "stats": [
                {
                  "base_stat": 110,
                  "stat": {
                    "name": "speed"
                  }
                }
              ],
              "types": [
                {
                  "type": {
                    "name": "ground"
                  }
                },
                {
                  "type": {
                    "name": "steel"
                  }
                }
              ],
              "sprites": {
                "front_default": "https://example.com/dugtrio-alola.png",
                "back_default": "https://example.com/dugtrio-alola-back.png",
                "front_shiny": "https://example.com/dugtrio-alola-shiny.png",
                "back_shiny": "https://example.com/dugtrio-alola-back-shiny.png",
                "other": {
                  "official-artwork": {
                    "front_default": "https://example.com/dugtrio-alola-art.png"
                  }
                }
              }
            }
            ''', 200);
        }

        if (request.url.path.contains('/pokemon-species/51')) {
          return http.Response('''
            {
              "name": "dugtrio",
              "is_legendary": false,
              "is_mythical": false,
              "generation": {
                "name": "generation-i"
              },
              "color": {
                "name": "brown"
              },
              "flavor_text_entries": [
                {
                  "flavor_text": "Forma un trio bajo tierra.",
                  "language": {
                    "name": "es"
                  }
                }
              ],
              "evolution_chain": {
                "url": "https://pokeapi.co/api/v2/evolution-chain/20/"
              }
            }
            ''', 200);
        }

        return http.Response('''
          {
            "chain": {
              "species": {
                "name": "diglett",
                "url": "https://pokeapi.co/api/v2/pokemon-species/50/"
              },
              "evolves_to": [
                {
                  "species": {
                    "name": "dugtrio",
                    "url": "https://pokeapi.co/api/v2/pokemon-species/51/"
                  },
                  "evolution_details": [
                    {
                      "trigger": {
                        "name": "level-up"
                      },
                      "min_level": 26
                    }
                  ],
                  "evolves_to": []
                }
              ]
            }
          }
          ''', 200);
      }),
    );

    final pokemon = await repository.fetchPokemonDetail(10106);

    expect(pokemon.name, 'Dugtrio Alola');
    expect(pokemon.generation, 7);
    expect(pokemon.speciesColor, 'Marron');
    expect(pokemon.formLabel, 'Alola');
    expect(pokemon.evolutionStage, PokemonEvolutionStage.finalStage);
    expect(pokemon.evolutionLine.map((step) => step.name), [
      'Diglett',
      'Dugtrio',
    ]);
    expect(pokemon.imageUrl, 'https://example.com/dugtrio-alola-art.png');
  });

  test('Fetches Pokemon metadata from species and evolution chain', () async {
    final repository = PokeApiPokemonRepository(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/pokemon-species/25')) {
          return http.Response('''
            {
              "name": "pikachu",
              "is_legendary": true,
              "is_mythical": false,
              "generation": {
                "name": "generation-i"
              },
              "color": {
                "name": "yellow"
              },
              "evolution_chain": {
                "url": "https://pokeapi.co/api/v2/evolution-chain/10/"
              }
            }
            ''', 200);
        }

        return http.Response('''
          {
            "chain": {
              "species": {
                "name": "pichu",
                "url": "https://pokeapi.co/api/v2/pokemon-species/172/"
              },
              "evolves_to": [
                {
                  "species": {
                    "name": "pikachu",
                    "url": "https://pokeapi.co/api/v2/pokemon-species/25/"
                  },
                  "evolution_details": [
                    {
                      "trigger": {
                        "name": "level-up"
                      },
                      "min_happiness": 220
                    }
                  ],
                  "evolves_to": [
                    {
                      "species": {
                        "name": "raichu",
                        "url": "https://pokeapi.co/api/v2/pokemon-species/26/"
                      },
                      "evolution_details": [
                        {
                          "trigger": {
                            "name": "use-item"
                          },
                          "item": {
                            "name": "thunder-stone"
                          }
                        }
                      ],
                      "evolves_to": []
                    }
                  ]
                }
              ]
            }
          }
          ''', 200);
      }),
    );

    final metadata = await repository.fetchPokemonMetadata(25);

    expect(metadata.name, 'Pikachu');
    expect(metadata.generation, 1);
    expect(metadata.speciesColor, 'Amarillo');
    expect(metadata.isLegendary, isTrue);
    expect(metadata.isMythical, isFalse);
    expect(metadata.evolvesByItem, isTrue);
    expect(metadata.evolutionStage, PokemonEvolutionStage.middle);
    expect(metadata.evolutionLine.map((step) => step.name), [
      'Pichu',
      'Pikachu',
      'Raichu',
    ]);
    expect(metadata.evolutionLine.last.method, 'Usar Thunder Stone');
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

  test('Reads the Pokemon catalog from local cache', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cacheStore = SharedPreferencesPokemonCacheStore(preferences);
    await cacheStore.writeCatalog(
      limit: 1,
      pokemon: const [
        PokemonPreview(id: 25, name: 'Pikachu', types: ['Electrico']),
      ],
    );

    final repository = PokeApiPokemonRepository(
      cacheStore: cacheStore,
      client: MockClient((request) async {
        throw Exception('Network should not be called');
      }),
    );

    final pokemon = await repository.fetchPokemonCatalog(limit: 1);

    expect(pokemon, hasLength(1));
    expect(pokemon.first.id, 25);
    expect(pokemon.first.name, 'Pikachu');
    expect(pokemon.first.types, ['Electrico']);
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
