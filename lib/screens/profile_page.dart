import 'package:flutter/material.dart';

import '../services/user_data_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userDataRepository,
    required this.isSupabaseConfigured,
  });

  final UserDataRepository userDataRepository;
  final bool isSupabaseConfigured;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<_ProfileStats> _statsFuture = _loadStats();

  Future<_ProfileStats> _loadStats() async {
    final favorites = await widget.userDataRepository.readFavoritePokemonIds();
    final notes = await widget.userDataRepository.readNotes();
    final teams = await widget.userDataRepository.readTeams();

    return _ProfileStats(
      favoriteCount: favorites.length,
      noteCount: notes.length,
      teamCount: teams.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Entrenador', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Icon(
                        Icons.person_outline,
                        size: 36,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invitado',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isSupabaseConfigured
                                ? 'Supabase configurado, login pendiente'
                                : 'Modo local sin Supabase configurado',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Resumen', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else
              _StatsGrid(stats: stats ?? _ProfileStats.empty()),
            const SizedBox(height: 24),
            Text('Cuenta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      widget.isSupabaseConfigured
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                    ),
                    title: Text(
                      widget.isSupabaseConfigured
                          ? 'Backend disponible'
                          : 'Backend no configurado',
                    ),
                    subtitle: const Text(
                      'El perfil se sincronizara cuando agreguemos autenticacion.',
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.badge_outlined),
                    title: Text('Perfil remoto'),
                    subtitle: Text(
                      'Preparado para nombre, titulo de entrenador y preferencias.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _StatTile(label: 'Favoritos', value: stats.favoriteCount),
        _StatTile(label: 'Notas', value: stats.noteCount),
        _StatTile(label: 'Equipos', value: stats.teamCount),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ProfileStats {
  const _ProfileStats({
    required this.favoriteCount,
    required this.noteCount,
    required this.teamCount,
  });

  factory _ProfileStats.empty() {
    return const _ProfileStats(favoriteCount: 0, noteCount: 0, teamCount: 0);
  }

  final int favoriteCount;
  final int noteCount;
  final int teamCount;
}
