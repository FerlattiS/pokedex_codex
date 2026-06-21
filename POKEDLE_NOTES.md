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

Pendientes para este modo:

- Agregar color de especie.
- Agregar formas regionales, megaevoluciones, Gigamax y variantes especiales.
- Mejorar altura y peso con pistas visuales mas claras.
- Limitar intentos diarios o configurar dificultad.
- Mostrar historial de intentos por dia.
- Persistir resultado diario y racha en perfil.
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
