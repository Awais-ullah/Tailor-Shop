# Tailor Shop documentation

Developer documentation for the Tailor Shop app. The [project README](../README.md) covers what the app does and a quick start. These pages go deeper.

| Page | Read it when you want to... |
|---|---|
| [Architecture](architecture.md) | Understand layers, startup, state management, offline writes, sync, routing, localisation and theming |
| [Data model & security rules](data-model.md) | Know every Firestore field and constraint, and how money integrity is enforced |
| [Development guide](development.md) | Set up, build, release, or make a common change (new string, garment, field, route) |
| [Project review](review.md) | See known issues, risks and recommended fixes, in priority order |

## At a glance

- **Stack:** Flutter (Material 3) · `flutter_bloc` Cubits · `go_router` · Firebase Auth · Cloud Firestore with offline persistence
- **Targets:** Android and Windows (iOS/macOS scaffolding present; Linux not supported by Firebase plugins)
- **Data:** `shops/{uid}/{customers, measurements, orders, payments}`, one owner per shop
- **Languages:** English, Urdu, Roman Urdu, Arabic, Chinese, Hindi
- **Key idea:** every feature works offline. Writes go to the local cache immediately and sync later, and the security rules re-check all money changes on the server.
