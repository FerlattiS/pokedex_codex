# POKEDLE PRO

## Vision

POKEDLE PRO sera una coleccion de minijuegos diarios relacionados a Pokemon.
El perfil de usuario deberia guardar intentos diarios, resultados, rachas y
mejores marcas cuando integremos autenticacion y sincronizacion.

## Modo principal: adivinar el Pokemon diario

Idea base:

- Se selecciona un Pokemon diario de forma deterministica por fecha.
- El usuario ingresa Pokemon como intentos.
- Cada intento se compara contra el Pokemon oculto.
- Se puede jugar con alcance Gen 1-2 o con todos los Pokemon.
- Se puede jugar en modo dificil con 10 intentos o facil sin limite.
- El resultado diario se guarda localmente para estadisticas de perfil.
- Verde significa coincidencia exacta.
- Rojo significa que no coincide.
- Amarillo significa coincidencia en otra posicion cuando aplica, por ejemplo
  Tipo 1 y Tipo 2 invertidos.

Comparaciones del MVP:

- Tipo 1.
- Tipo 2.
- Generacion.
- Etapa evolutiva.
- Rareza: normal, legendario o mitico.
- Altura.
- Peso.
- Stat mas alto.

Ya implementado:

- Selector de alcance Gen 1-2/Todos.
- Selector de dificultad Facil/Dificil.
- Historial local de resultados por fecha, alcance y dificultad.
- Perfil general con pestana Pokedle, partidas, victorias, racha actual,
  mejor racha, ratio de victoria y promedio de intentos ganados.

Pendientes para este modo:

- Agregar color de especie.
- Agregar formas regionales, megaevoluciones, Gigamax y variantes especiales.
- Mejorar altura y peso con pistas visuales mas claras.
- Mostrar historial de intentos por dia.
- Separar estadisticas por modo y dificultad.
- Sincronizar progreso con Supabase cuando exista login.
- Agregar animacion o estado especial al ganar.

## Idea pendiente: mayor battle stats total

Minijuego futuro:

- Se muestran 2 Pokemon.
- El usuario debe adivinar cual tiene mas battle stats totales.
- Se muestra cuantos aciertos seguidos puede lograr.
- El perfil deberia registrar maxima racha, racha actual, partidas jugadas y
  mejor marca diaria.

No implementar todavia; queda registrado para retomarlo mas adelante.
