import 'package:firebase_core/firebase_core.dart';

/// Turns Firestore error codes into messages a shop owner understands.
class FirestoreErrorMapper {
  FirestoreErrorMapper._();

  static const String _generic = 'Something went wrong. Please try again.';

  static String fromError(Object error) {
    if (error is FirebaseException) return message(error.code);
    return _generic;
  }

  static String message(String code) {
    switch (code) {
      case 'permission-denied':
        return "You don't have permission to perform this action.";
      case 'unavailable':
      case 'network-request-failed':
        return "Can't reach the server right now. Changes are kept on this "
            "device and will sync when you're back online.";
      case 'deadline-exceeded':
        return 'The server took too long to respond. Please try again.';
      case 'not-found':
        return 'That record could not be found. It may have been removed.';
      case 'already-exists':
        return 'That record already exists.';
      case 'unauthenticated':
        return 'Your session has expired. Please sign in again.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return _generic;
    }
  }
}