/// Turns Firebase Auth error codes into messages a shop owner understands.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String message(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address does not look right.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your connection and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this app.';
      case 'password-does-not-meet-requirements':
        return 'That password is not strong enough. Use upper and lower case '
            'letters, a number and a symbol.';
      case 'configuration-not-found':
      case 'internal-error':
      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'Sign-in is not set up correctly for this app. Please contact '
            'support.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}