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
- Filtros avanzados por favoritos, stats, movimiento, rareza, composicion de tipos y evolucion.
- Orden por numero y nombre.
- Vista de lista y vista de cuadricula.
- Colores por tipo en chips, bordes y tarjetas.
- Borde visible por tipo real en tarjetas de lista y cuadricula.
- Insignias L/M en tarjetas para Pokemon legendarios y miticos.
- Menu inicial para elegir Pokedex, hub de juegos, minijuegos, perfil o favoritos.
- Menu lateral con Pokedex, favoritos, perfil, About us, Help, Settings, Juegos, Daily Randommon, POKEDLE PRO, Higher or Lower, 15 Preguntas y Quit.
- Modo claro y modo oscuro.
- Persistencia local del modo claro y modo oscuro.
- Pantalla real de Settings con preferencias y estado de datos locales.
- Daily Randommon funcional con favorito, detalle, nota rapida y opcion de ver otro aleatorio.
- POKEDLE PRO con Pokemon diario, intentos locales, comparacion de atributos, color, forma, modos Gen 1-2/Todos y dificultad facil/dificil.
- POKEDLE PRO permite copiar un resultado textual al portapapeles para compartir.
- Higher or Lower para elegir cual Pokemon tiene mayor stat, mantener racha, historial visual, modos por alcance/stat y rondas tipo cola.
- 15 Preguntas como minijuego diario de preguntas si/no con estado local, resultado historico, compartir, preguntas por habitat y region, resumen visual final, selectores de categoria y pregunta, 15 preguntas maximas y 3 intentos de respuesta.
- 15 Preguntas recuerda categoria, permite buscar/favoritar preguntas y confirma antes de gastar intentos.
- Pantalla de detalle de Pokemon con descripcion, tipos, altura, peso, habilidades, stats y movimientos.
- Linea evolutiva en el detalle con metodo de evolucion.
- Dialogo de habilidad con descripcion, nombre en ingles y detalle tecnico.
- Movimientos agrupados por metodo de aprendizaje.
- Detalle competitivo de movimientos con tipo, clase, poder, PP y precision.
- Cache local para catalogo, detalle, habilidades y movimientos de PokeAPI.
- Cache versionada con vencimiento, limites, fallback offline, estadisticas y limpieza desde Settings.
- Capa de red con timeout y reintentos breves ante fallos temporales.
- Repositorio local de datos de usuario para favoritos, notas y equipos.
- Repositorio local comun de resultados de juegos.
- Favoritos locales desde tarjetas y detalle de Pokemon.
- Pantalla dedicada para ver Pokemon favoritos.
- Pantalla de perfil de usuario con resumen local, estado de Supabase, historial/rachas de Pokedle y pestana Juegos.
- Pantallas reales de About us y Help.
- Disclaimer fan-made y educativo visible en About us.
- Cliente Supabase opcional por variables de entorno.
- Migracion inicial de Supabase para favoritos, notas y equipos con RLS.
- Migracion de Supabase para perfil de usuario con RLS.
- Repositorio remoto base para datos de usuario en Supabase.
- Interfaz preparada para reemplazar la persistencia local por Supabase.
- Pruebas de widgets y repositorio actualizadas para los flujos principales.
- Guia de publicacion web/mobile en `PUBLICACION.md`.
- Roadmap priorizado de producto en `ROADMAP.md`.

## Falta por hacer

- Ajustes de accesibilidad y responsive fino para web y Android.
- Pantallas de equipos y notas usando el repositorio local actual.
- Autenticacion con Supabase.
- Conectar el repositorio remoto de Supabase al flujo autenticado.
- Edicion del perfil de usuario.
- Sincronizacion de favoritos con Supabase.
- Sincronizacion de equipos con Supabase.
- Sincronizacion de notas personales con Supabase.
- Configuracion de proyecto Supabase en dashboard.
- Expandir POKEDLE PRO con mas atributos, estadisticas por modo y sincronizacion.
- Mas pruebas sobre rangos de stats, estados de error y flujos autenticados.

## Comandos utiles

```bash
flutter analyze
flutter test
```

## Supabase

La app esta preparada para crear un cliente Supabase sin hardcodear claves. Por
ahora se usa el paquete Dart `supabase` para evitar cargar plugins web de
autenticacion que todavia no estamos usando.

### Funcion en el proyecto

Supabase es la capa de backend para datos propios del usuario. PokeAPI sigue
siendo la fuente de datos publica de Pokemon; Supabase no reemplaza ese catalogo.

Responsabilidades de Supabase:

- Autenticar usuarios cuando se agregue login.
- Guardar favoritos, notas personales y equipos por usuario.
- Guardar datos de perfil propios de la app, como nombre visible, titulo de entrenador y preferencias.
- Proteger esos datos con RLS para que cada usuario lea y escriba solo lo suyo.
- Servir como punto de sincronizacion entre web, Android y futuros dispositivos.
- Mantener datos de perfil cuando esa pantalla exista.

Fuera de alcance para Supabase:

- No almacena el catalogo completo de Pokemon.
- No reemplaza la cache local de PokeAPI.
- No guarda claves privadas ni service role keys dentro de la app.
- No resuelve reglas de UI; la app sigue validando y presentando la experiencia.

Estado actual de la integracion:

- El cliente Supabase se crea solo si existen variables `--dart-define`.
- La app sigue usando persistencia local mientras no exista usuario autenticado.
- Ya existen migraciones SQL para tablas y politicas RLS.
- Ya existe un repositorio remoto base para favoritos, notas y equipos.
- Ya existe una pantalla de perfil que muestra resumen local y estado de cuenta.
- Falta conectar ese repositorio al flujo real de autenticacion y sincronizacion.

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
- La migracion de perfil esta en `supabase/migrations/202606210002_create_user_profiles_table.sql`.
- Esa migracion crea `user_profiles`.
- Todas las tablas usan RLS con `auth.uid() = user_id`.
- Para aplicarla desde el dashboard, abre SQL Editor y ejecuta el archivo completo.
