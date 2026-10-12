import 'package:equatable/equatable.dart';
import 'package:tailor_app/features/auth/data/models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isBusy = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Who is logged in. The router reads this to decide which screens
  /// are allowed.
  final AuthStatus status;
  final AppUser? user;

  /// True while a sign-in / sign-up / reset / sign-out is running.
  final bool isBusy;

  /// One-time messages. The UI shows them as snackbars.
  final String? errorMessage;
  final String? successMessage;

  @override
  List<Object?> get props =>
      [status, user, isBusy, errorMessage, successMessage];
}