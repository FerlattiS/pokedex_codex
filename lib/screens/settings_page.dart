import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.isSupabaseConfigured,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final bool isSupabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Preferencias', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Modo oscuro'),
            subtitle: const Text('Se guarda localmente en este dispositivo.'),
            value: isDarkMode,
            onChanged: onDarkModeChanged,
          ),
        ),
        const SizedBox(height: 24),
        Text('Supabase', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(
              isSupabaseConfigured
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
            ),
            title: Text(
              isSupabaseConfigured ? 'Configurado' : 'No configurado',
            ),
            subtitle: const Text(
              'Usa SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY con --dart-define.',
            ),
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
                subtitle: Text('Guardados localmente hasta sumar Supabase.'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.cached_outlined),
                title: Text('Cache de PokeAPI'),
                subtitle: Text(
                  'Reduce cargas repetidas del catalogo y detalle.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.cloud_sync_outlined),
                title: Text('Sincronizacion'),
                subtitle: Text('Preparado para conectar autenticacion y nube.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
