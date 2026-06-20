import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Guia rapida', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.search),
                title: Text('Buscar Pokemon'),
                subtitle: Text(
                  'Abri Busqueda y filtros para escribir un nombre parcial.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.filter_alt_outlined),
                title: Text('Filtrar y ordenar'),
                subtitle: Text(
                  'Combina tipos, generaciones y orden por numero o nombre.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.grid_view),
                title: Text('Cambiar vista'),
                subtitle: Text(
                  'Usa lista o cuadricula desde la barra superior.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Detalles', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Ficha de Pokemon'),
                subtitle: Text(
                  'Toca una tarjeta para ver descripcion, stats y movimientos.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.bolt_outlined),
                title: Text('Habilidades y movimientos'),
                subtitle: Text(
                  'Toca cada habilidad o movimiento para abrir su detalle.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.today_outlined),
                title: Text('Daily Randommon'),
                subtitle: Text('Descubre un Pokemon distinto cada dia.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Datos locales', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.star_outline),
                title: Text('Favoritos'),
                subtitle: Text(
                  'Marca Pokemon con la estrella y revisalos desde el menu.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Preferencias'),
                subtitle: Text(
                  'El modo oscuro y tus datos se guardan en este dispositivo.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
