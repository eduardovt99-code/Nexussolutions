# NEXUS — El sistema operativo de tu reforma

App Flutter para reformistas en España: presupuestos, cuadrilla, Pro-Calc y cobros.

## Usar la demo online

**URL:** https://eduardovt99-code.github.io/Nexussolutions/

Entra con cualquier correo y contraseña (demo sin backend). Los datos se guardan en el navegador de cada usuario.

## Correr en local

```bash
flutter pub get
flutter run -d chrome
```

## Publicar cambios en la web

Cada push a `main` despliega automáticamente la versión web en GitHub Pages.

```bash
git add .
git commit -m "Descripción del cambio"
git push
```

## Stack

- Flutter (web, Android, iOS, Windows)
- Datos locales con `shared_preferences` (demo)
