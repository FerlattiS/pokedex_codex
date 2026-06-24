import 'package:flutter/material.dart';

import '../services/pokemon_cache_store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.isSupabaseConfigured,
    this.pokemonCacheStore,
    this.onClearPokemonCache,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final bool isSupabaseConfigured;
  final PokemonCacheStore? pokemonCacheStore;
  final Future<void> Function()? onClearPokemonCache;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<PokemonCacheStats?> _cacheStats = _readCacheStats();

  Future<PokemonCacheStats?> _readCacheStats() {
    return widget.pokemonCacheStore?.readStats() ??
        Future<PokemonCacheStats?>.value();
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpiar cache?'),
          content: const Text(
            'Los datos se volveran a descargar cuando abras la Pokedex o un juego.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Limpiar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await widget.onClearPokemonCache?.call();
    await widget.pokemonCacheStore?.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _cacheStats = _readCacheStats();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cache de PokeAPI limpiada')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Preferencias', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text('Modo oscuro'),
            subtitle: const Text('Se guarda localmente en este dispositivo.'),
            value: widget.isDarkMode,
            onChanged: widget.onDarkModeChanged,
          ),
        ),
        const SizedBox(height: 24),
        Text('Supabase', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(
              widget.isSupabaseConfigured
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
            ),
            title: Text(
              widget.isSupabaseConfigured ? 'Configurado' : 'No configurado',
            ),
            subtitle: const Text(
              'Usa SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY con --dart-define.',
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Datos locales', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.star_outline),
                title: Text('Favoritos'),
                subtitle: Text('Guardados localmente hasta sumar Supabase.'),
              ),
              const Divider(height: 1),
              FutureBuilder<PokemonCacheStats?>(
                future: _cacheStats,
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  final subtitle = stats == null
                      ? 'No disponible en este entorno.'
                      : '${stats.totalEntries} entradas - ${_formatBytes(stats.approximateBytes)}';
                  return ListTile(
                    leading: const Icon(Icons.cached_outlined),
                    title: const Text('Cache de PokeAPI'),
                    subtitle: Text(subtitle),
                    trailing: widget.pokemonCacheStore == null
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar cache',
                            onPressed: stats?.totalEntries == 0
                                ? null
                                : _clearCache,
                            icon: const Icon(Icons.delete_outline),
                          ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'El catalogo vence a los 7 dias; detalles, habilidades y movimientos se renuevan periodicamente. Si no hay red se usa la ultima copia disponible.',
                ),
              ),
              const Divider(height: 1),
              const ListTile(
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
}
