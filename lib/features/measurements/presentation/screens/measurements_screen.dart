import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/widgets/customer_picker_dialog.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_cubit.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_state.dart';
import 'package:tailor_app/features/measurements/presentation/widgets/garment_picker_sheet.dart';
import 'package:tailor_app/features/measurements/presentation/widgets/measurement_card.dart';

/// Pick a customer, pick a garment, then open the form.
Future<void> _startNewMeasurement(BuildContext context) async {
  final customers = context
      .read<CustomersCubit>()
      .state
      .customers
      .where((customer) => !customer.isArchived)
      .toList();

  if (customers.isEmpty) {
    AppSnackbar.showError(
      context,
      'Add a customer first, then record their measurements.',
    );
    return;
  }

  final customer = await showCustomerPicker(context, customers);
  if (customer == null || !context.mounted) return;

  final garment = await showGarmentPicker(context);
  if (garment == null || !context.mounted) return;

  context.push(AppRoutes.measurementNewFor(customer.id, garment.id));
}

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MeasurementsCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Measurements')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _startNewMeasurement(context),
        icon: const Icon(Icons.add),
        label: const Text('New measurements'),
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: cubit.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by customer or label',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          cubit.setQuery('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const _GarmentFilterBar(),
          const Expanded(child: _Content()),
        ],
      ),
    );
  }
}

class _GarmentFilterBar extends StatelessWidget {
  const _GarmentFilterBar();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MeasurementsCubit>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: BlocBuilder<MeasurementsCubit, MeasurementsState>(
          buildWhen: (previous, current) =>
          previous.garmentFilter != current.garmentFilter,
          builder: (context, state) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: state.garmentFilter == null,
                    onSelected: (_) => cubit.setGarmentFilter(null),
                  ),
                  for (final type in GarmentType.values) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(type.label),
                      selected: state.garmentFilter == type,
                      onSelected: (_) => cubit.setGarmentFilter(type),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementsCubit>().state;
    final customersState = context.watch<CustomersCubit>().state;

    switch (state.status) {
      case MeasurementsStatus.loading:
        return const LoadingView();
      case MeasurementsStatus.failure:
        return ErrorState(
          message: state.errorMessage ?? 'Could not load measurements.',
          onRetry: context.read<MeasurementsCubit>().retry,
        );
      case MeasurementsStatus.loaded:
        break;
    }

    // Build the lookup once instead of searching per item.
    final names = {
      for (final customer in customersState.customers) customer.id: customer.name,
    };
    String nameOf(String id) => names[id] ?? 'Unknown customer';

    final items = state.filtered(nameOf);

    if (items.isEmpty) {
      final hasFilters =
          state.query.trim().isNotEmpty || state.garmentFilter != null;

      if (hasFilters) {
        return const EmptyState(
          icon: Icons.search_off,
          title: 'No matches',
          message: 'No measurements match your search or filter.',
        );
      }
      return EmptyState(
        icon: Icons.straighten_outlined,
        title: 'No measurements yet',
        message: "Your customers' saved measurements will appear here.",
        actionLabel: 'New measurements',
        onAction: () => _startNewMeasurement(context),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return MeasurementCard(
              measurement: item,
              customerName: nameOf(item.customerId),
              onTap: () => context.push(AppRoutes.measurementDetails(item.id)),
            );
          },
        ),
      ),
    );
  }
}