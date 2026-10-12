import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/utils/validators.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:tailor_app/features/auth/presentation/widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthCubit>().sendPasswordReset(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
      (current.errorMessage != null &&
          current.errorMessage != previous.errorMessage) ||
          (current.successMessage != null &&
              current.successMessage != previous.successMessage),
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppSnackbar.showError(context, state.errorMessage!);
        } else if (state.successMessage != null) {
          AppSnackbar.showSuccess(context, state.successMessage!);
          context.pop();
        }
      },
      child: AuthScaffold(
        title: 'Reset your password',
        subtitle: "Enter your email and we'll send you a link to reset it.",
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
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
                      : const Text('Send reset link'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}