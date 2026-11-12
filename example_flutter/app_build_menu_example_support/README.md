# app_build_menu_example_support

Build tools for `../app_build_menu_example` run from another package (the
app path is given to the menu and the builders):

- `tool/example_build_menu.dart`: the app menu (`menuAppContent`) plus host
  build and run items.
- `tool/build_and_serve_chrome_wasm.dart`: a wasm web build served locally;
  `tool/run_chrome_wasm.dart`: `flutter run` in Chrome.
- `test/build_and_run_test.dart`: creates the platform folder of the app and
  builds it (desktop hosts only).
