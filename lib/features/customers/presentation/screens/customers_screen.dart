import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_state.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          BlocBuilder<CustomersCubit, CustomersState>(
            buildWhen: (previous, current) =>
            previous.showArchived != current.showArchived,
            builder: (context, state) => IconButton(
              tooltip: state.showArchived
                  ? 'Show active customers'
                  : 'Show archived customers',
              icon: Icon(
                state.showArchived
                    ? Icons.people_outline
                    : Icons.inventory_2_outlined,
              ),
              onPressed: cubit.toggleArchived,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoutes.customerNew),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add customer'),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: cubit.setQuery,
            onClear: () {
              _searchController.clear();
              cubit.setQuery('');
            },
          ),
          Expanded(
            child: BlocBuilder<CustomersCubit, CustomersState>(
              builder: (context, state) => _Content(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by name or phone',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final CustomersState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CustomersStatus.loading:
        return const LoadingView();
      case CustomersStatus.failure:
        return ErrorState(
          message: state.errorMessage ?? 'Could not load customers.',
          onRetry: context.read<CustomersCubit>().retry,
        );
      case CustomersStatus.loaded:
        break;
    }

    final customers = state.visibleCustomers;
    if (customers.isEmpty) return _EmptyContent(state: state);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          // Extra bottom padding keeps the last item clear of the button.
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: customers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _CustomerTile(customer: customers[index]),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({required this.state});

  final CustomersState state;

  @override
  Widget build(BuildContext context) {
    final query = state.query.trim();

    if (query.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        message: 'No customers match "$query".',
      );
    }
    if (state.showArchived) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No archived customers',
        message: 'Customers you archive will appear here.',
      );
    }
    return EmptyState(
      icon: Icons.people_outline,
      title: 'No customers yet',
      message: 'Add your first customer to get started.',
      actionLabel: 'Add customer',
      onAction: () => context.push(AppRoutes.customerNew),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.customerDetails(customer.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  customer.initial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
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
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.phone.isEmpty
                          ? 'No phone number'
                          : customer.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slate500),
            ],
          ),
        ),
      ),
    );
  }
}