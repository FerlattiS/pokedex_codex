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
- Color de especie.
- Forma: normal, regional, mega, Gigamax u otras variantes reconocidas.
- Altura.
- Peso.
- Stat mas alto.

Ya implementado:

- Selector de alcance Gen 1-2/Todos.
- Selector de dificultad Facil/Dificil.
- Historial local de resultados por fecha, alcance y dificultad.
- Perfil general con pestana Pokedle, partidas, victorias, racha actual,
  mejor racha, ratio de victoria y promedio de intentos ganados.
- Comparacion por color.
- Comparacion por forma.
- Copia de resultado textual al portapapeles.

Pendientes para este modo:

- Refinar deteccion de formas especiales menos comunes.
- Mejorar altura y peso con pistas visuales mas claras.
- Mostrar historial de intentos por dia.
- Separar estadisticas por modo y dificultad.
- Sincronizar progreso con Supabase cuando exista login.

### Compartir resultado

El boton "Copiar resultado" usa `Clipboard.setData`, por eso no necesita
permisos nativos ni dependencias extra. En vez de abrir el menu de compartir del
sistema, copia un texto que el usuario puede pegar donde quiera.

Formato actual:

- Encabezado con fecha, modo y cantidad de intentos.
- Una fila por intento.
- Cada celda se resume con una letra: `V` para verde, `A` para amarillo y `R`
  para rojo.

Mas adelante se puede reemplazar o complementar por `share_plus` si queremos
abrir el share sheet nativo de Android/iOS/Web. Eso agregaria una dependencia y
habria que revisar comportamiento por plataforma.

## Higher or Lower: mayor battle stats total

Minijuego implementado:

- Se muestran 2 Pokemon.
- El usuario debe adivinar cual tiene mas battle stats totales.
- Se muestra cuantos aciertos seguidos puede lograr.
- Las rondas avanzan como una cola: el segundo Pokemon del duelo anterior pasa
  a la izquierda y se enfrenta contra uno nuevo.
- Cada Pokemon participa como maximo en 2 duelos consecutivos, para evitar que
  un Pokemon con BST muy alto bloquee la jugabilidad durante demasiadas rondas.
- El historial visual muestra duelos recientes, seleccion del usuario y ganador.
- Se puede cambiar el alcance entre Gen 1-2, todos o sin legendarios/miticos.
- Se puede comparar por BST total o por un stat puntual.
- El perfil deberia registrar maxima racha, racha actual, partidas jugadas y
  mejor marca diaria.

Pendiente:

- Persistir racha continua entre sesiones.
- Mostrar desglose de stats al revelar resultado.

## 15 Preguntas

Minijuego diario implementado:

- Se selecciona un Pokemon de forma deterministica por fecha.
- El usuario puede hacer hasta 15 preguntas de si/no.
- Tiene 3 intentos para adivinar el Pokemon correcto.
- El estado diario queda guardado localmente para que no se reinicie al salir al
  menu y volver.
- Al ganar o perder se guarda un resultado comun de juego para el perfil.
- Se puede copiar un resumen textual al portapapeles.
- Las preguntas estan categorizadas por generacion, tipo, color, rareza,
  composicion de tipos, forma alternativa, evolucion por objeto y etapa
  evolutiva.
- Generacion incluye preguntas exactas y rangos, por ejemplo si salio antes o
  despues de determinada generacion.
- Tambien hay preguntas por altura, peso, stat mas alto, habilidades y
  movimientos comunes.
- La interfaz separa la categoria de la pregunta en dos selectores y muestra
  cuantas opciones quedan disponibles dentro de cada categoria.

Pendientes:

- Mejorar el set de preguntas con habitat o region.
- Ampliar movimientos y habilidades disponibles sin volver lenta la carga.

## Perfil de juegos

Implementado como primera version local. La idea es convertir el perfil actual
en un centro de progreso para todos los minijuegos, no solo Pokedle.

Datos utiles por juego:

- Partidas jugadas.
- Victorias.
- Racha actual.
- Mejor racha.
- Resultado del dia.
- Historial diario.
- Mejor marca por modo o dificultad.
- Ultima fecha jugada.

Modelo actual:

- Una tabla/coleccion local y luego remota llamada `game_results`.
- Campos comunes: `user_id`, `game_id`, `date_key`, `won`, `score`,
  `attempts`, `streak`, `metadata`, `completed_at`.
- `metadata` guardaria detalles propios de cada juego, por ejemplo preguntas de
  15 Preguntas o filas de Pokedle.

Ventajas:

- Evita crear una tabla distinta por cada minijuego.
- Permite mostrar estadisticas comparables entre juegos.
- Facilita sincronizar con Supabase cuando haya login.
- Permite sumar rankings o logros mas adelante sin reescribir todo el perfil.
