// Entrypoint for Flutter Driver (automated UI testing).
// Run with: flutter run -t lib/driver_main.dart -d chrome
// Then connect with Dart Tooling Daemon and use flutter_driver commands (tap, enter_text, get_text, etc.).
// ignore: depend_on_referenced_packages
import 'package:flutter_driver/driver_extension.dart';
import 'main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
