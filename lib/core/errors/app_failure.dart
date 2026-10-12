/// A user-friendly error. The message is safe to show on screen.
/// Technical details are logged separately, never shown to the user.
class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}