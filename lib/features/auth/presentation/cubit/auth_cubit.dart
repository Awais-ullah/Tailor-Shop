import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/features/auth/data/models/app_user.dart';
import 'package:tailor_app/features/auth/data/repositories/auth_repository.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState()) {
    _subscription = _repository.userChanges().listen(
      _onUserChanged,
      onError: (_) => emit(
        const AuthState(status: AuthStatus.unauthenticated),
      ),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  void _onUserChanged(AppUser? user) {
    emit(
      AuthState(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
        isBusy: state.isBusy,
      ),
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
          () => _repository.signUp(name: name, email: email, password: password),
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _run(
          () => _repository.sendPasswordReset(email),
      successMessage:
      'If an account exists for that email, a reset link has been sent.',
    );
  }

  Future<void> signOut() => _run(_repository.signOut);

  Future<void> _run(
      Future<void> Function() action, {
        String? successMessage,
      }) async {
    if (state.isBusy) return;

    // Clearing old messages first means the same error can show twice.
    emit(AuthState(status: state.status, user: state.user, isBusy: true));

    try {
      await action();
      emit(
        AuthState(
          status: state.status,
          user: state.user,
          successMessage: successMessage,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        AuthState(
          status: state.status,
          user: state.user,
          errorMessage: failure.message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}