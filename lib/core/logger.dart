import 'dart:developer' as developer;

enum LogLevel { trace, debug, info, warn, error }

/// Minimal structured logger. Writes via `dart:developer.log` so DevTools
/// timeline picks it up, and prints in debug builds.
///
/// Real production logging (Sentry, file rotation) wires up later through
/// `LogSink.global` — keep `Log` calls in feature code; swap the sink.
class Log {
  final String tag;
  const Log(this.tag);

  void trace(String msg, {Object? error, StackTrace? stack}) =>
      _emit(LogLevel.trace, msg, error: error, stack: stack);
  void debug(String msg, {Object? error, StackTrace? stack}) =>
      _emit(LogLevel.debug, msg, error: error, stack: stack);
  void info(String msg, {Object? error, StackTrace? stack}) =>
      _emit(LogLevel.info, msg, error: error, stack: stack);
  void warn(String msg, {Object? error, StackTrace? stack}) =>
      _emit(LogLevel.warn, msg, error: error, stack: stack);
  void error(String msg, {Object? error, StackTrace? stack}) =>
      _emit(LogLevel.error, msg, error: error, stack: stack);

  void _emit(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
  }) {
    LogSink.global.write(
      LogRecord(
        level: level,
        tag: tag,
        message: message,
        error: error,
        stack: stack,
        timestamp: DateTime.now(),
      ),
    );
  }
}

class LogRecord {
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stack;
  final DateTime timestamp;

  const LogRecord({
    required this.level,
    required this.tag,
    required this.message,
    required this.timestamp,
    this.error,
    this.stack,
  });
}

abstract class LogSink {
  static LogSink global = const _DevSink();
  void write(LogRecord record);
}

class _DevSink implements LogSink {
  const _DevSink();
  @override
  void write(LogRecord record) {
    developer.log(
      record.message,
      time: record.timestamp,
      name: record.tag,
      level: _levelInt(record.level),
      error: record.error,
      stackTrace: record.stack,
    );
    // Also print to stdout so the message appears in `flutter logs` /
    // logcat without needing to attach DevTools. Cheap; no formatting
    // overhead on hot paths.
    // ignore: avoid_print
    print('[${record.level.name}] ${record.tag}: ${record.message}'
        '${record.error != null ? ' — ${record.error}' : ''}');
  }

  int _levelInt(LogLevel l) => switch (l) {
        LogLevel.trace => 300,
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      };
}
