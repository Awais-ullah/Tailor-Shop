import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/widgets/app_logo.dart';

/// Shared layout for Login / Sign up / Forgot password.
/// Wide screens: brand panel + form. Phones: a single scrollable form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  static const double _splitBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showBrandPanel = width >= _splitBreakpoint;
    final textTheme = Theme.of(context).textTheme;

    final form = _ScrollCenter(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!showBrandPanel) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AppLogo(size: 48),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                title,
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
              ),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: showBrandPanel
          ? Row(
        children: [
          const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(flex: 4, child: form),
        ],
      )
          : SafeArea(child: form),
    );
  }
}

/// Centers content when there is spare room, and scrolls when there isn't
/// (for example when the keyboard is open on a small phone).
class _ScrollCenter extends StatelessWidget {
  const _ScrollCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.primary,
      child: _ScrollCenter(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 56, inverted: true),
                const SizedBox(height: 24),
                Text(
                  'Tailor Shop',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Customers, measurements, orders and payments in one place.',
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                const _Feature(
                  icon: Icons.cloud_off_outlined,
                  text: 'Keeps working without internet',
                ),
                const SizedBox(height: 16),
                const _Feature(
                  icon: Icons.straighten_outlined,
                  text: 'Saved measurements for every customer',
                ),
                const SizedBox(height: 16),
                const _Feature(
                  icon: Icons.account_balance_wallet_outlined,
                  text: 'Clear balances and payment history',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}