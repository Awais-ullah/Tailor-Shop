import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/features/auth/data/auth_error_mapper.dart';
import 'package:tailor_app/features/auth/data/models/app_user.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// The ONLY class that talks to Firebase Auth.
/// Everything above it (Cubits, screens) works with AppUser and AppFailure.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emits the saved user on app start (works offline), and again on
  /// sign-in, sign-out and profile changes.
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_toAppUser);

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _guard(
          () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // The account exists at this point. A failure to save the display
      // name must not make signup look like it failed.
      try {
        await credential.user?.updateDisplayName(name.trim());
        await credential.user?.reload();
      } catch (e) {
        debugPrint('[AuthRepository] could not save display name: $e');
      }
    });
  }

  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() => _guard(() => _auth.signOut());

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthRepository] ${e.code}: ${e.message}');
      final message = AuthErrorMapper.message(e.code);
      throw AppFailure(kDebugMode ? '$message [${e.code}]' : message);
    } catch (e) {
      debugPrint('[AuthRepository] unexpected error: $e');
      throw AppFailure(
        kDebugMode
            ? S.current.errorGenericDetail(e)
            : S.current.errorGeneric,
      );
    }
  }
}