import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class PerfTrace {
  static void mark(String label, {Map<String, Object?> extras = const {}}) {
    if (!kDebugMode) return;
    developer.log(
      'perf:$label',
      name: 'perf',
      error: extras.isEmpty ? null : extras,
    );
  }

  static Future<T> timeAsync<T>(
    String label,
    Future<T> Function() run, {
    Map<String, Object?> extras = const {},
  }) async {
    final sw = Stopwatch()..start();
    try {
      return await run();
    } finally {
      sw.stop();
      mark(label, extras: {
        ...extras,
        'ms': sw.elapsedMilliseconds,
      });
    }
  }
}

