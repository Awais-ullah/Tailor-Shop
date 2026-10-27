import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/widgets/customer_picker_dialog.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_cubit.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_state.dart';
import 'package:tailor_app/features/measurements/presentation/widgets/garment_picker_sheet.dart';
import 'package:tailor_app/features/measurements/presentation/widgets/measurement_card.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';

import '../../../../core/widgets/fade_slide_in.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';

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
      S.current.addCustomerFirstMeasure,
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
      appBar: AppBar(title: Text(S.current.measurements)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.pal.brand,
        foregroundColor: AppColors.gold,
        onPressed: () => _startNewMeasurement(context),
        icon: const Icon(Icons.add),
        label: Text(S.current.newMeasurements),
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: cubit.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: S.current.searchCustomerOrLabel,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                        tooltip: S.current.clearSearch,
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
                    label: Text(S.current.all),
                    selected: state.garmentFilter == null,
                    onSelected: (_) => cubit.setGarmentFilter(null),
                  ),
                  for (final type in GarmentType.values) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: TailorIcon(TailorGlyphs.garment(type), size: 20),
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
          message: state.errorMessage ?? S.current.couldNotLoadMeasurements,
          onRetry: context.read<MeasurementsCubit>().retry,
        );
      case MeasurementsStatus.loaded:
        break;
    }

    // Build the lookup once instead of searching per item.
    final names = {
      for (final customer in customersState.customers) customer.id: customer.name,
    };
    String nameOf(String id) => names[id] ?? S.current.unknownCustomer;

    final items = state.filtered(nameOf);

    if (items.isEmpty) {
      final hasFilters =
          state.query.trim().isNotEmpty || state.garmentFilter != null;

      if (hasFilters) {
        return EmptyState(
          icon: Icons.search_off,
          title: S.current.noMatches,
          message: S.current.noMeasurementsMatch,
        );
      }
      return EmptyState(
        icon: Icons.straighten_outlined,
        title: S.current.noMeasurementsYet,
        message: S.current.savedMeasurementsAppear,
        actionLabel: S.current.newMeasurements,
        onAction: () => _startNewMeasurement(context),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 96),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return FadeSlideIn(
              delay: Duration(milliseconds: 35 * (index < 8 ? index : 8)),
              child: MeasurementCard(
                measurement: item,
                customerName: nameOf(item.customerId),
                onTap: () =>
                    context.push(AppRoutes.measurementDetails(item.id)),
              ),
            );
          },
        ),
      ),
    );
  }
}