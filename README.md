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
