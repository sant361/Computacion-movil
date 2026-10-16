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
