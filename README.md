# Streaming App

Proyecto base en Flutter para la aplicación móvil de streaming,
construido a partir de los wireframes y los requerimientos funcionales.

## Estructura

```
lib/
  main.dart
  screens/
    auth/            # Login, registro, recuperación, verificación, 2FA, dispositivos
    payments/         # Planes, pago, resultado, métodos, suscripción, facturación
    home_screen.dart
    menu_screen.dart
    search_screen.dart
    player_screen.dart
```

## Cómo continuar

1. `flutter pub get`
2. `flutter run`
3. Sigue agregando pantallas en `lib/screens/` y commits pequeños por funcionalidad.

## Pruebas automatizadas

El proyecto incluye pruebas en `test/`:

- `app_state_test.dart`: pruebas unitarias de la lógica de tokens, Mi lista, descargas y sesión (no necesitan abrir ninguna pantalla).
- `login_screen_test.dart`: prueba de interfaz de la pantalla de Login (validación de campos, autocompletar, mostrar/ocultar contraseña).

Para correrlas, dentro de la carpeta del proyecto:

```
flutter test
```

## Integración continua (GitHub Actions)

El archivo `.github/workflows/flutter-ci.yml` hace que GitHub corra automáticamente
`flutter analyze` y `flutter test` cada vez que subes un cambio (`git push`) a la
rama `main`, o cuando abres un pull request. Si algo falla, aparece una ❌ roja
junto al commit en GitHub (en vez de enterarte solo cuando lo corres tú mismo
en tu computador). Puedes ver el resultado en la pestaña **Actions** del
repositorio en GitHub.

## Progreso de reproducción sincronizado

El progreso local se sincroniza con Cloud Firestore en
`users/{uid}/watchProgress/{id}` al iniciar sesión con Firebase Authentication.
Cada documento corresponde a un título y al nombre de un perfil; para retomarlo
en otro dispositivo, inicia sesión con la misma cuenta y selecciona el mismo
perfil. Los perfiles personalizados todavía se crean localmente, por lo que
su nombre debe coincidir en ambos dispositivos.

Los cambios se envían cada 10 segundos y al pausar, salir del reproductor o pasar
la app a segundo plano. Una escucha recibe cambios del otro dispositivo.
SharedPreferences conserva el progreso y los cambios pendientes sin conexión;
se reintentan al recuperar acceso a Firestore. El reproductor espera hasta
3 segundos por la primera lectura y luego permite usar la copia local.

Se conserva la modificación más reciente según la fecha del dispositivo
(microsegundos), incluso si el usuario retrocede. Los relojes de los dispositivos
deben estar ajustados automáticamente. Las transacciones impiden sobrescribir
una versión más reciente con un pendiente antiguo. Un registro con posición
cero propaga reinicios y finalizaciones; así una copia antigua no reaparece en
«Seguir viendo». Los historiales locales anteriores se migran sin reemplazar
un progreso que ya esté en la nube.

### Reglas requeridas en Firebase

En la consola del proyecto `streaming-app-e0850`, abre **Firestore Database →
Reglas**. Integra el bloque de `firebase/watch-progress.rules` dentro de
`match /databases/{database}/documents` y publica las reglas conservando las
reglas existentes para catálogo, administradores y otras colecciones. Revisa
que no exista una regla general que permita leer datos de cualquier usuario:
las reglas permisivas también se aplican a las subcolecciones.

El archivo contiene un bloque para integrar, no una configuración completa
para desplegar. No se modificaron las reglas publicadas desde este repositorio.
Si las reglas no permiten el acceso, la app conserva el avance local y muestra
«Sincronización pendiente» con la opción de reintentar.

Pruebas: `flutter test test/progress_sync_test.dart` verifica sincronización
entre estados independientes, aislamiento por cuenta/perfil, reintentos tras
reiniciar, conflictos, reinicios, finalizaciones y migración usando un almacén
en memoria. La prueba real requiere dos dispositivos autenticados contra el
mismo proyecto y las reglas anteriores publicadas: avanza un título, pausa y
abre ese perfil en el segundo dispositivo; repite sin conexión y al reconectar.
No se ejecutó una prueba con cuentas reales ni un despliegue de reglas.

## Catálogo, reproducción y biblioteca

Las pantallas existentes ahora admiten videos por título, temporadas y episodios,
reproducción automática del siguiente capítulo, tráileres, portadas, subtítulos
SRT/WebVTT y temporizador. Los archivos multimedia se configuran desde
Administración → Contenido, usando enlaces HTTP(S) accesibles al dispositivo.
En web, el servidor de archivos debe permitir CORS. Los títulos de muestra no
se sustituyen por películas ajenas: si falta la URL se informa en el reproductor.
Los enlaces de un servicio que requiera DRM o autorización adicional necesitan
una integración específica; pegar la URL de una página no equivale a un video.

El editor conserva los identificadores de Firestore y permite modificar o
eliminar contenido, además de editar episodios con su temporada y número.
Los episodios guardan avances independientes. El buscador mantiene los filtros
por género, año, idioma y duración y la búsqueda de títulos sin acentos.

Los favoritos, valoraciones, historial y preferencias se guardan por cuenta y
perfil. La sección Seguir viendo permite quitar títulos; el historial puede
borrarse con confirmación. Las valoraciones influyen en las recomendaciones.
El historial visible borrado, favoritos y valoraciones son locales al dispositivo;
la posición de reproducción y los metadatos de perfiles sí se sincronizan.

Los perfiles admiten avatar por icono o URL HTTPS y clasificación infantil.
Un perfil infantil solo muestra contenido permitido y no administra perfiles,
catálogo ni controles parentales. Antes de entrar en él hay que configurar un
adulto con PIN, para poder volver de forma segura. El PIN de 4 a 6 dígitos se
almacena como derivación PBKDF2 con sal; cinco errores bloquean nuevos intentos
30 segundos en ese dispositivo. El PIN es una protección dentro de la app,
no una segunda identidad de Firebase ni un control DRM. No compartas las
credenciales de Firebase con usuarios que deban tener permisos diferentes.

Los perfiles y avatares se sincronizan en `users/{uid}/profiles`, con pendientes
locales y reintentos. Los estrenos y capítulos nuevos se detectan al actualizar
el catálogo (al entrar y cada dos minutos mientras se usa la app). Los avisos
aparecen en el centro de notificaciones, con lectura y preferencia persistentes;
no son notificaciones push del sistema cuando la app está cerrada.

Cada inicio real de reproducción registra un evento en
`users/{uid}/playEvents`; no se cuentan los tráileres. La sección Analítica
agrupa estos eventos reales por título y género. Solo las cuentas con documento
`admins/{uid}` pueden consultar el conjunto de eventos o editar el catálogo.
Los eventos pendientes se reintentan al recuperar acceso a Firebase.

### Configuración pendiente del proyecto Firebase

`firebase/firestore.rules` contiene reglas para catálogo, perfiles, progreso y
estadísticas. Revisa e integra estas reglas en el proyecto `streaming-app-e0850`
sin perder reglas de otras funciones que ya utilices. No hay credenciales de
despliegue administrativo en esta sesión y las reglas no se han publicado.
El alta de administradores se realiza desde un entorno administrativo confiable;
la app no puede concederse ese permiso.

Para verificar la integración real, publica las reglas, configura títulos con
URLs propias y usa dos dispositivos con la misma cuenta: crea un perfil, cambia
su avatar y comprueba la sincronización; reproduce un episodio, pausa y retómalo
en el otro dispositivo. Comprueba también que un infantil no puede abrir un
título restringido o gestionar perfiles, y que otra cuenta no ve esos datos.
Las pruebas automatizadas usan almacenes y reproductor simulados, no cuentas
reales ni descargas completas de archivos multimedia.
