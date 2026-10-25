import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// Shows who is logged in, with a Sign out button.
class AccountTile extends StatelessWidget {
  const AccountTile({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final cubit = context.read<AuthCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.current.signOutQuestion),
        content: Text(
          S.current.signOutBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.current.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) cubit.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (previous, current) =>
      previous.user != current.user || previous.isBusy != current.isBusy,
      builder: (context, state) {
        final user = state.user;
        final storedName = user?.displayName?.trim() ?? '';
        final name = storedName.isEmpty ? S.current.shopOwner : storedName;

        return SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: context.pal.primarySoft,
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            color: context.pal.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.pal.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed:
                    state.isBusy ? null : () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout),
                    label: Text(S.current.signOut),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}