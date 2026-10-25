import 'package:firebase_core/firebase_core.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// Turns Firestore error codes into messages a shop owner understands.
class FirestoreErrorMapper {
  FirestoreErrorMapper._();

  static String get _generic => S.current.errorGeneric;

  static String fromError(Object error) {
    if (error is FirebaseException) return message(error.code);
    return _generic;
  }

  static String message(String code) {
    switch (code) {
      case 'permission-denied':
        return S.current.errorPermission;
      case 'unavailable':
      case 'network-request-failed':
        return S.current.errorOffline;
      case 'deadline-exceeded':
        return S.current.errorTimeout;
      case 'not-found':
        return S.current.errorNotFound;
      case 'already-exists':
        return S.current.errorExists;
      case 'unauthenticated':
        return S.current.errorSessionExpired;
      case 'resource-exhausted':
        return S.current.errorTooManyRequests;
      default:
        return _generic;
    }
  }
}