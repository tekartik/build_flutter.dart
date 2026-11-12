# app_build_menu_example

Example Flutter app for `tekartik_build_menu_flutter` (desktop and Android
builds from a console menu).

- `tool/default_build_menu.dart`: the default app menu (`menuAppContent`).
- `tool/example_build_menu.dart`: plus items to build and run the host
  (Linux, Windows) app, an Android run and an apk build (a connected device
  is needed).
- `lib/create_file_and_exit_main.dart`: an entry point that writes
  `.dart_tool/app_build_menu_example/data/marker.txt` next to the built
  executable and exits, used by `test/build_and_run_test.dart` (creates the
  platform folder, builds, runs the app and checks the marker; the run is
  skipped on GitHub Linux runners, the marker not checked on macOS).

```bash
dart run tool/example_build_menu.dart
```
