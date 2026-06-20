import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Pokedex Codex Pro',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Una Pokedex rapida y clara para explorar Pokemon, guardar '
              'favoritos y preparar futuras funciones de equipos, notas y '
              'sincronizacion con Supabase.',
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Enfoque', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.catching_pokemon),
                title: Text('Catalogo completo'),
                subtitle: Text(
                  'Datos desde PokeAPI con busqueda, filtros y detalle.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.speed_outlined),
                title: Text('Experiencia fluida'),
                subtitle: Text(
                  'Cache local para reducir esperas y cargas repetidas.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.cloud_sync_outlined),
                title: Text('Lista para crecer'),
                subtitle: Text(
                  'Favoritos locales hoy, sincronizacion y perfil mas adelante.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Roadmap', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.groups_outlined),
                title: Text('Equipos y notas'),
                subtitle: Text('Pantallas dedicadas usando datos locales.'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.login_outlined),
                title: Text('Autenticacion'),
                subtitle: Text('Conexion con Supabase para guardar en nube.'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.sports_esports_outlined),
                title: Text('POKEDLE PRO'),
                subtitle: Text(
                  'Juego derivado cuando la app base este solida.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
