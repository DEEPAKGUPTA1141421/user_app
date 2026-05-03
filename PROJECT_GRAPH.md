# Project Graph

Generated from Dart imports under `lib/`.

## Module Dependency Graph

```mermaid
graph TD
  main["main.dart"]
  layout["main_layout.dart"]
  components["components"]
  constant["constant"]
  core["core"]
  model["model"]
  provider["provider"]
  screens["screens"]
  utils["utils"]
  widgets["widgets"]

  main --> layout
  main --> utils
  layout --> screens
  layout --> widgets

  components --> core
  components --> provider
  components --> utils
  components --> widgets

  constant --> core
  core --> utils
  model --> utils
  provider --> core
  provider --> model

  screens --> core
  screens --> model
  screens --> provider
  screens --> utils
  screens --> widgets
  screens --> components

  widgets --> core
  widgets --> model
  widgets --> provider
  widgets --> screens
  widgets --> utils
```

## Heaviest Internal Edges

| Imports | Edge |
| ---: | --- |
| 59 | `provider -> core` |
| 47 | `screens -> provider` |
| 30 | `widgets -> provider` |
| 28 | `widgets -> utils` |
| 26 | `screens -> utils` |
| 26 | `screens -> core` |
| 21 | `widgets -> model` |
| 16 | `widgets -> core` |
| 8 | `screens -> widgets` |
| 5 | `core -> utils` |

## File Counts By Area

| Files | Area |
| ---: | --- |
| 71 | `widgets` |
| 34 | `screens` |
| 22 | `provider` |
| 8 | `core` |
| 7 | `utils` |
| 4 | `model` |
| 1 | `components` |
| 1 | `constant` |
| 1 | `firebase_options.dart` |
| 1 | `main.dart` |
| 1 | `main_layout.dart` |
| 1 | `unknown_page.dart` |

## External Package Hotspots

```mermaid
graph LR
  app["user_app"]
  riverpod["flutter_riverpod: 67"]
  dio["dio: 23"]
  shimmer["shimmer: 13"]
  image_picker["image_picker: 4"]
  phonepe["phonepe_payment_sdk: 3"]
  firebase_core["firebase_core: 2"]
  url_launcher["url_launcher: 2"]
  misc["other packages: 7"]

  app --> riverpod
  app --> dio
  app --> shimmer
  app --> image_picker
  app --> phonepe
  app --> firebase_core
  app --> url_launcher
  app --> misc
```

## Runtime Shape

```mermaid
graph TD
  start["main()"]
  firebase["Firebase init and messaging"]
  app["MyApp"]
  splash["SplashScreen"]
  storage["StorageService"]
  login["LoginScreen"]
  home["MainLayout"]
  tabs["Home / Shops / Categories / People / Cart"]
  routes["Named and generated routes"]
  api["ApiClient singleton"]
  auth["AuthInterceptor"]
  endpoints["ApiEndpoints"]

  start --> firebase
  start --> app
  app --> splash
  splash --> storage
  splash --> login
  splash --> home
  home --> tabs
  app --> routes
  routes --> tabs
  api --> auth
  api --> endpoints
  auth --> storage
  auth --> endpoints
```

## Reading Notes

- `core/api` is the API foundation: `ApiClient` builds Dio clients, `AuthInterceptor` attaches and refreshes tokens, and `ApiEndpoints` centralizes paths.
- `provider` depends heavily on `core`, which suggests providers are the main data-access layer.
- `screens` and `widgets` are the widest consumers of providers and shared utilities.
- `widgets` imports `screens` once, which is worth watching because it can make UI composition harder to untangle over time.
