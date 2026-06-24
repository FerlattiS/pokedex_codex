# Publicacion web, Android e iOS

Esta nota resume que haria falta para compartir Pokedex Codex Pro sin buscar
monetizacion, priorizando opciones gratis o de costo minimo. No es asesoria
legal, pero sirve como mapa de decisiones antes de publicar.

## Objetivo recomendado por ahora

El camino mas barato y simple es publicar primero la version web. Flutter ya
puede generar una app web estatica, y eso permite compartir un link sin pasar
por tiendas, sin pagar cuentas de desarrollador y sin instalar APKs.

Orden sugerido:

1. Web publica para feedback.
2. APK Android compartido por fuera de Play Store para testers de confianza.
3. Google Play si vale la pena pagar el alta y pasar el proceso de revision.
4. iOS/App Store solo si se justifica el costo anual y el trabajo extra.

## Web

Flutter genera archivos HTML, CSS, JS y assets estaticos con:

```bash
flutter build web
```

Para GitHub Pages en un repositorio de proyecto normalmente hace falta indicar
el `base-href` con el nombre del repo:

```bash
flutter build web --base-href /pokedex_codex/
```

Opciones gratis:

- GitHub Pages: permite alojar sitios estaticos desde un repositorio. En GitHub
  Free esta disponible para repositorios publicos.
- Netlify, Vercel o Cloudflare Pages: suelen tener planes gratuitos, pero hay
  que revisar sus limites antes de usarlos.

Costos posibles:

- Hosting: puede ser gratis con GitHub Pages.
- Dominio propio: opcional y normalmente pago anual. Si alcanza con un subdominio
  tipo `github.io`, no hace falta.
- Backend: por ahora se puede evitar. Si se usa Supabase, conviene mantenerse
  dentro del plan gratuito mientras el proyecto sea chico.

Ventajas:

- Cero instalacion para quien prueba.
- Mas facil de actualizar.
- Evita costos de tiendas.
- Ideal para recibir feedback temprano.

Limitaciones:

- La experiencia puede sentirse menos "app nativa" que Android/iOS.
- Algunas funciones moviles avanzadas pueden requerir trabajo extra.
- Si hay login o datos personales, igual hace falta pensar privacidad.

## Android

### Sin Google Play

Se puede generar un APK y compartirlo directamente:

```bash
flutter build apk --release
```

Esto no tiene costo directo, pero Android muestra advertencias al instalar apps
por fuera de Play Store. Es razonable solo para testers conocidos.

### Con Google Play

Para publicar en Google Play hace falta una cuenta de Play Console. Google
indica una tarifa unica de registro de USD 25. Las cuentas personales nuevas
tambien pueden tener requisitos de testing antes de publicar publicamente.

Build recomendado para Play Store:

```bash
flutter build appbundle --release
```

Cosas necesarias:

- Nombre final de app.
- Icono y screenshots.
- Package id definitivo, por ejemplo `com.tuusuario.pokedexcodex`.
- Firma de release y resguardo de la key.
- Politica de privacidad si la app recolecta datos o usa login.
- Ficha de Play Store, clasificacion de contenido y declaracion de datos.
- Test cerrado/abierto si Google lo exige para la cuenta.

Costos posibles:

- USD 25 una sola vez para Play Console.
- No hace falta pagar hosting si la app usa PokeAPI y persistencia local.
- Si se suma Supabase con muchos usuarios, puede aparecer costo de backend.

## iOS

Para desarrollar y probar en un dispositivo propio se puede usar una Apple
Account gratis con Xcode, pero Apple marca limitaciones: perfiles que vencen,
limites de App IDs y limites de dispositivos.

Para TestFlight o App Store hace falta Apple Developer Program. Apple informa
un costo de USD 99 por anio de membresia.

Cosas necesarias:

- Mac con Xcode.
- Bundle id definitivo.
- Certificados y provisioning profiles.
- Iconos, screenshots y metadata para App Store Connect.
- Politica de privacidad y declaracion de datos.
- Revision de App Store.

Costos posibles:

- USD 99 por anio para Apple Developer Program.
- Posible costo de Mac si no se tiene una.

Para este proyecto, iOS no parece el primer paso si la prioridad es no pagar.

## Backend y datos

La app hoy puede funcionar sin backend real para compartir una demo:

- PokeAPI entrega los datos publicos de Pokemon.
- La app guarda favoritos, historial y preferencias localmente.
- Supabase puede quedar apagado si no se pasan variables de entorno.

Supabase seria necesario cuando queramos:

- Login de usuario.
- Sincronizar favoritos, perfil, historial y rachas entre dispositivos.
- Tener rankings o estadisticas compartidas.
- Recuperar datos si el usuario cambia de equipo.

Para mantenerlo gratis:

- Evitar login al principio.
- Mantener cache local.
- No guardar imagenes ni catalogo completo propio en Supabase.
- Agregar limites razonables a escrituras si algun dia hay rankings.

## Temas legales y de marca

Puntos importantes:

- PokeAPI dice que los nombres de Pokemon y personajes son marcas de Nintendo.
- Este proyecto no debe presentarse como oficial ni afiliado a Nintendo, The
  Pokemon Company, Game Freak o Creatures.
- Aunque no haya monetizacion, usar personajes, sprites, nombres y marcas puede
  tener riesgo si se publica ampliamente.
- Conviene agregar un disclaimer visible en README, About us y pagina web.
- Evitar usar logos oficiales de Pokemon o una identidad visual que parezca
  producto oficial.
- Evitar anuncios, compras internas, suscripciones o donaciones vinculadas a la
  marca Pokemon.
- Si se sube a tiendas, la revision puede rechazar la app por propiedad
  intelectual aunque sea gratuita.

Disclaimer sugerido:

```text
Pokedex Codex Pro es un proyecto fan-made y educativo. No esta afiliado,
respaldado ni aprobado por Nintendo, The Pokemon Company, Game Freak o
Creatures. Los nombres, personajes y marcas de Pokemon pertenecen a sus
respectivos propietarios.
```

## Privacidad

Si no hay login ni analytics, la privacidad es mas simple, pero igual conviene
dejar claro:

- Que datos se guardan localmente.
- Que se consulta PokeAPI para cargar informacion publica.
- Si se usa Supabase o analytics en el futuro.
- Como se puede borrar la informacion local.

Si se publica en Google Play o App Store, probablemente haya que completar
formularios de privacidad aunque la app sea gratuita.

## Checklist minimo para una demo publica web

Implementado:

1. Disclaimer en README y About us.
2. Supabase opcional y sin claves incluidas.
3. Metadatos, iconos y manifest PWA propios.
4. Rutas compartibles mediante hash.
5. Entornos `development`, `beta` y `production`.
6. CI con analisis, tests y build web.
7. Workflow de GitHub Pages para la rama `web-beta`.

Paso manual pendiente en GitHub:

1. Abrir `Settings > Pages`.
2. En `Build and deployment`, elegir `GitHub Actions`.
3. Pushear la rama `web-beta` o ejecutar manualmente `Deploy web beta`.
4. Esperar que finalice el workflow.
5. Abrir `https://ferlattis.github.io/pokedex_codex/`.

Build local equivalente:

```bash
flutter build web \
  --release \
  --base-href /pokedex_codex/ \
  --dart-define=APP_ENV=beta \
  --dart-define=APP_VERSION=local
```

La beta no incluye credenciales de Supabase. Favoritos, preferencias e
historial quedan guardados en el navegador de cada persona.

## Fuentes utiles

- GitHub Pages: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
- Google Play Console: https://support.google.com/googleplay/android-developer/answer/6112435
- Apple Developer Program: https://developer.apple.com/support/compare-memberships/
- PokeAPI About: https://pokeapi.co/about
