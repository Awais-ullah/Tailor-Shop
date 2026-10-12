import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/utils/validators.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:tailor_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:tailor_app/features/auth/presentation/widgets/password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthCubit>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
      current.errorMessage != null &&
          current.errorMessage != previous.errorMessage,
      listener: (context, state) =>
          AppSnackbar.showError(context, state.errorMessage!),
      child: AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to manage your shop.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: 'Password',
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) =>
                    Validators.requiredField(value, fieldName: 'Password'),
                onSubmitted: _submit,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<AuthCubit, AuthState>(
                buildWhen: (previous, current) =>
                previous.isBusy != current.isBusy,
                builder: (context, state) => FilledButton(
                  onPressed: state.isBusy ? null : _submit,
                  child: state.isBusy
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.signup),
                    child: const Text('Create one'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}