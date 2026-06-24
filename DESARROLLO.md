# Desarrollo y arquitectura

## Entornos

La app usa valores de compilacion para distinguir ambientes:

```bash
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=APP_VERSION=local
```

Valores admitidos para `APP_ENV`:

- `development`: trabajo local.
- `beta`: version compartida para pruebas.
- `production`: futura version estable.

No se deben guardar secretos en `--dart-define` para Flutter web porque los
valores compilados pueden inspeccionarse desde el navegador.

## Navegacion

Las rutas estan centralizadas en:

- `lib/navigation/app_destination.dart`
- `lib/navigation/app_router.dart`

Rutas principales:

- `/`
- `/pokedex`
- `/favorites`
- `/profile`
- `/games`
- `/games/pokedle`
- `/games/higher-or-lower`
- `/games/15-preguntas`

En web se conserva la estrategia con hash, por ejemplo
`/#/games/pokedle`. Esto permite refrescar y compartir enlaces en GitHub Pages
sin configurar redirecciones del servidor.

## Estructura recomendada

Al agregar funcionalidades nuevas:

1. Definir modelos y reglas fuera de los widgets.
2. Acceder a datos mediante interfaces de repositorio.
3. Mantener persistencia local y remota intercambiables.
4. Crear widgets compartidos para patrones visuales repetidos.
5. Registrar la pantalla en `MainMenuDestination`.
6. Agregar pruebas de reglas, persistencia y flujo principal.

Para un minijuego nuevo conviene separar:

- `models/`: estado, reglas y comparaciones.
- `services/`: progreso, resultados y acceso a datos.
- `screens/`: composicion de la experiencia.
- `widgets/`: controles y visualizaciones reutilizables.

## Integracion continua

`.github/workflows/ci.yml` ejecuta:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. build web beta

El workflow se ejecuta en pushes a ramas principales y en pull requests.

## Beta web

`.github/workflows/deploy-pages.yml` contiene el despliegue a GitHub Pages y se
ejecuta manualmente. GitHub Pages requiere que este repositorio sea publico con
el plan actual. Cuando Pages este habilitado se puede agregar nuevamente el
trigger por push a `web-beta`.

Build equivalente local:

```bash
flutter build web \
  --release \
  --base-href /pokedex_codex/ \
  --dart-define=APP_ENV=beta \
  --dart-define=APP_VERSION=local
```

La carpeta `build/web` es un artefacto generado y no debe commitearse.
