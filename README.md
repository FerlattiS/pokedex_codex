# Pokedex Codex Pro

Aplicacion Pokedex hecha con Flutter para web y Android.

## Objetivo inicial

Construir una Pokedex rapida, clara y extensible que consuma PokeAPI. Mas adelante el proyecto sumara Supabase para autenticacion, favoritos, equipos y notas.

## Estado actual

- Proyecto Flutter configurado con Material 3.
- Pantalla principal con catalogo completo de Pokemon desde PokeAPI.
- Carga inicial optimizada con datos livianos y cache en memoria.
- Busqueda por nombre.
- Filtros por tipo y generacion.
- Orden por numero y nombre.
- Vista de lista y vista de cuadricula.
- Colores por tipo en chips, bordes y tarjetas.
- Borde visible por tipo en tarjetas de lista y cuadricula.
- Menu principal con Pokedex, About us, Help, Settings, Daily Randommon, POKEDLE PRO y Quit.
- Modo claro y modo oscuro.
- Persistencia local del modo claro y modo oscuro.
- Pantalla real de Settings con preferencias y estado de datos locales.
- Daily Randommon funcional.
- Pantalla de detalle de Pokemon con descripcion, tipos, altura, peso, habilidades, stats y movimientos.
- Dialogo de habilidad con descripcion, nombre en ingles y detalle tecnico.
- Movimientos agrupados por metodo de aprendizaje.
- Detalle competitivo de movimientos con tipo, clase, poder, PP y precision.
- Cache local para catalogo, detalle, habilidades y movimientos de PokeAPI.
- Repositorio local de datos de usuario para favoritos, notas y equipos.
- Favoritos locales desde tarjetas y detalle de Pokemon.
- Pantalla dedicada para ver Pokemon favoritos.
- Pantallas reales de About us y Help.
- Cliente Supabase opcional por variables de entorno.
- Migracion inicial de Supabase para favoritos, notas y equipos con RLS.
- Interfaz preparada para reemplazar la persistencia local por Supabase.
- Pruebas de widgets y repositorio actualizadas para los flujos principales.

## Falta por hacer

- Ajustes de accesibilidad y responsive fino para web y Android.
- Pantallas de equipos y notas usando el repositorio local actual.
- Autenticacion con Supabase.
- Repositorio remoto para sincronizar favoritos con Supabase.
- Sincronizacion de equipos con Supabase.
- Sincronizacion de notas personales con Supabase.
- Configuracion de proyecto Supabase en dashboard.
- Perfil de usuario.
- POKEDLE PRO como proyecto derivado cuando la app base este mas solida.
- Mas pruebas sobre filtros combinados, detalle de movimientos y estados de error.

## Comandos utiles

```bash
flutter analyze
flutter test
```

## Supabase

La app esta preparada para crear un cliente Supabase sin hardcodear claves. Por
ahora se usa el paquete Dart `supabase` para evitar cargar plugins web de
autenticacion que todavia no estamos usando.

Para iniciar Supabase en la app, pasa la URL del proyecto y la publishable key:

```bash
flutter run --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=tu_publishable_key
```

Notas:

- `SUPABASE_URL` sale del dashboard del proyecto.
- `SUPABASE_PUBLISHABLE_KEY` es la clave publica para clientes Flutter.
- No usar service role keys en la app.
- La app sigue funcionando con datos locales si esas variables no estan.
- La migracion inicial esta en `supabase/migrations/202606210001_create_user_data_tables.sql`.
- Esa migracion crea `favorite_pokemon`, `pokemon_notes` y `pokemon_teams`.
- Todas las tablas usan RLS con `auth.uid() = user_id`.
- Para aplicarla desde el dashboard, abre SQL Editor y ejecuta el archivo completo.
