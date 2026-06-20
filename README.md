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
- Interfaz preparada para reemplazar la persistencia local por Supabase.
- Pruebas de widgets y repositorio actualizadas para los flujos principales.

## Falta por hacer

- Ajustes de accesibilidad y responsive fino para web y Android.
- Pantallas de equipos y notas usando el repositorio local actual.
- Sincronizacion de favoritos con Supabase.
- Sincronizacion de equipos con Supabase.
- Sincronizacion de notas personales con Supabase.
- Autenticacion con Supabase.
- Configuracion de proyecto Supabase y variables de entorno.
- Perfil de usuario.
- POKEDLE PRO como proyecto derivado cuando la app base este mas solida.
- Mas pruebas sobre filtros combinados, detalle de movimientos y estados de error.

## Comandos utiles

```bash
flutter analyze
flutter test
```
