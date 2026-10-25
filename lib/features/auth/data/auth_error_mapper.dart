import 'package:tailor_app/core/l10n/app_strings.dart';
/// Turns Firebase Auth error codes into messages a shop owner understands.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String message(String code) {
    switch (code) {
      case 'invalid-email':
        return S.current.authInvalidEmail;
      case 'user-disabled':
        return S.current.authDisabled;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return S.current.authBadCredentials;
      case 'email-already-in-use':
        return S.current.authEmailInUse;
      case 'weak-password':
        return S.current.authWeakPassword;
      case 'too-many-requests':
        return S.current.authTooManyAttempts;
      case 'network-request-failed':
        return S.current.authNoInternet;
      case 'operation-not-allowed':
        return S.current.authEmailNotEnabled;
      case 'password-does-not-meet-requirements':
        return S.current.authPasswordNotStrong;
      case 'configuration-not-found':
      case 'internal-error':
      case 'invalid-api-key':
      case 'app-not-authorized':
        return S.current.authNotSetUp;
      default:
        return S.current.errorGeneric;
    }
  }
}