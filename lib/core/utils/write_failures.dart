import 'dart:async';

/// A tiny message bus: any code can report that a save was rejected,
/// and the app shows the user one dialog about it.
class WriteFailures {
  WriteFailures._();

  static final StreamController<String> _controller =
  StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  static void report(String message) => _controller.add(message);
}