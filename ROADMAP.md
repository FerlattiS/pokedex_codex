# Roadmap de producto

## Fase actual: calidad y base tecnica

- Mejoras de uso en 15 Preguntas: categoria recordada, buscador, preguntas
  favoritas y confirmacion antes de gastar intentos.
- Lenguaje visual compartido para revelados, estados y tipos.
- Separacion de reglas de juego, persistencia y widgets.
- Reintentos, timeout y recuperacion desde cache cuando PokeAPI no responde.
- Cache versionada, con vencimiento, limites, estadisticas y limpieza manual.

## Proxima fase prioritaria

Estos tres bloques merecen una etapa propia de diseno antes de implementarlos:

### Estadisticas avanzadas

- Rachas diarias reales y reglas claras para conservarlas o perderlas.
- Resultados separados por juego, modo y dificultad.
- Promedios, distribuciones y evolucion semanal/mensual.
- Historial visual navegable sin mezclar partidas de practica.

### Perfil de entrenador

- Nombre, avatar y Pokemon representativo.
- Nivel general basado en actividad, no solamente en victorias.
- Resumen de juegos favoritos y mejores marcas.
- Preparado para funcionar localmente y sincronizarse mas adelante.

### Misiones y logros

- Logros permanentes y misiones diarias/semanales.
- Condiciones interesantes, no basadas solo en repetir partidas.
- Insignias vinculadas al perfil de entrenador.
- Recompensas visuales sin ventajas que rompan los juegos.

Antes de desarrollar esta fase conviene definir el modelo comun de progreso para
evitar rehacer estadisticas, perfil y logros por separado.
