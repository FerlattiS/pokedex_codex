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
- Menu principal con Pokedex, About us, Help, Settings, Daily Randommon, POKEDLE PRO y Quit.
- Modo claro y modo oscuro.
- Daily Randommon funcional.
- Pantalla de detalle de Pokemon con descripcion, tipos, altura, peso, habilidades, stats y movimientos.
- Dialogo de habilidad con descripcion, nombre en ingles y detalle tecnico.
- Movimientos agrupados por metodo de aprendizaje.
- Detalle competitivo de movimientos con tipo, clase, poder, PP y precision.
- Pruebas de widgets y repositorio actualizadas para los flujos principales.

## Falta por hacer

- Persistencia local mas fuerte para mejorar cache entre sesiones.
- Pantallas reales de About us, Help y Settings.
- Ajustes de accesibilidad y responsive fino para web y Android.
- Favoritos con Supabase.
- Equipos con Supabase.
- Notas personales con Supabase.
- Autenticacion con Supabase.
- Perfil de usuario.
- POKEDLE PRO como proyecto derivado cuando la app base este mas solida.
- Mas pruebas sobre filtros combinados, detalle de movimientos y estados de error.

## Comandos utiles

```bash
flutter analyze
flutter test
```
