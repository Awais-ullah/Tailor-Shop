import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_state.dart';
import 'package:tailor_app/features/measurements/presentation/widgets/garment_picker_sheet.dart';
import 'package:tailor_app/features/measurements/presentation/widgets/measurement_card.dart';

import '../cubit/measurements_cubit.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// The "Measurements" tab on a customer's profile.
class CustomerMeasurementsTab extends StatelessWidget {
  const CustomerMeasurementsTab({super.key, required this.customerId});

  final String customerId;

  Future<void> _add(BuildContext context) async {
    final garment = await showGarmentPicker(context);
    if (garment == null || !context.mounted) return;
    context.push(AppRoutes.customerMeasurementNew(customerId, garment.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeasurementsCubit, MeasurementsState>(
      builder: (context, state) {
        switch (state.status) {
          case MeasurementsStatus.loading:
            return const LoadingView();
          case MeasurementsStatus.failure:
            return ErrorState(
              message: state.errorMessage ?? S.current.couldNotLoadMeasurements,
              onRetry: context.read<MeasurementsCubit>().retry,
            );
          case MeasurementsStatus.loaded:
            break;
        }

        final items = state.forCustomer(customerId);
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.straighten_outlined,
            title: S.current.noMeasurementsYet,
            message:
            S.current.saveCustomerMeasurements,
            actionLabel: S.current.addMeasurements,
            onAction: () => _add(context),
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: () => _add(context),
                  icon: const Icon(Icons.add),
                  label: Text(S.current.addMeasurements),
                ),
                const SizedBox(height: 12),
                for (final item in items) ...[
                  MeasurementCard(
                    measurement: item,
                    onTap: () => context.push(
                      AppRoutes.customerMeasurementDetails(customerId, item.id),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}