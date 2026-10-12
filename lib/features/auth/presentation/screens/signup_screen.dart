import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/utils/validators.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:tailor_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:tailor_app/features/auth/presentation/widgets/password_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthCubit>().signUp(
      name: _nameController.text,
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
        title: 'Create your account',
        subtitle: 'Set up the owner account for your shop.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) =>
                    Validators.requiredField(value, fieldName: 'Your name'),
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.newPassword,
                onSubmitted: () => _confirmFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmController,
                focusNode: _confirmFocus,
                label: 'Confirm password',
                textInputAction: TextInputAction.done,
                validator: (value) => Validators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
                onSubmitted: _submit,
              ),
              const SizedBox(height: 24),
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
                      : const Text('Create account'),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Sign in'),
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