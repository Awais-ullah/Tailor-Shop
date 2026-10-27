import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/features/measurements/presentation/screens/measurements_screen.dart';
import 'package:tailor_app/features/orders/presentation/screens/orders_screen.dart';

/// The raised round "+" in the middle of the phone's bottom bar.
///
/// A plain widget rather than a FloatingActionButton: no Hero, so it never
/// clashes with the pages' own "New ..." buttons during transitions.
class QuickAddButton extends StatelessWidget {
  const QuickAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const double size = 60;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: S.current.quickAdd,
      child: Tooltip(
        message: S.current.quickAdd,
        excludeFromSemantics: true,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x5907343E),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: const Icon(Icons.add_rounded, size: 32, color: AppColors.gold),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with the everyday "new" actions. Each one closes the sheet
/// and then runs with [context] (the shell's), which can read the cubits.
Future<void> showQuickAddSheet(BuildContext context) {
  void run(BuildContext sheetContext, void Function() action) {
    Navigator.of(sheetContext).pop();
    action();
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.current.quickAdd,
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _QuickAddAction(
                icon: Icons.receipt_long_outlined,
                title: S.current.newOrder,
                subtitle: S.current.quickAddOrderHint,
                onTap: () => run(sheetContext, () => startNewOrder(context)),
              ),
              const SizedBox(height: 10),
              _QuickAddAction(
                icon: Icons.person_add_alt_1_outlined,
                title: S.current.newCustomer,
                subtitle: S.current.quickAddCustomerHint,
                onTap: () => run(
                  sheetContext,
                  () => context.push(AppRoutes.customerNew),
                ),
              ),
              const SizedBox(height: 10),
              _QuickAddAction(
                icon: Icons.straighten_outlined,
                title: S.current.newMeasurements,
                subtitle: S.current.quickAddMeasurementHint,
                onTap: () =>
                    run(sheetContext, () => startNewMeasurement(context)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _QuickAddAction extends StatelessWidget {
  const _QuickAddAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.pal.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.pal.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.pal.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: context.pal.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: context.pal.slate500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.pal.slate500),
            ],
          ),
        ),
      ),
    );
  }
}
