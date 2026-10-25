import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_state.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';

import '../../../../core/widgets/fade_slide_in.dart';

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
        title: Text(S.current.customers),
        actions: [
          BlocBuilder<CustomersCubit, CustomersState>(
            buildWhen: (previous, current) =>
            previous.showArchived != current.showArchived,
            builder: (context, state) => IconButton(
              tooltip: state.showArchived
                  ? S.current.showActiveCustomers
                  : S.current.showArchivedCustomers,
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
        backgroundColor: context.pal.brand,
        foregroundColor: AppColors.gold,
        onPressed: () => context.push(AppRoutes.customerNew),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(S.current.addCustomer),
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
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: S.current.searchNameOrPhone,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                  tooltip: S.current.clearSearch,
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
          message: state.errorMessage ?? S.current.couldNotLoadCustomers,
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
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 96),
          itemCount: customers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => FadeSlideIn(
            delay: Duration(milliseconds: 35 * (index < 8 ? index : 8)),
            child: _CustomerTile(customer: customers[index]),
          ),
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
        title: S.current.noMatches,
        message: S.current.noCustomersMatch(query),
      );
    }
    if (state.showArchived) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: S.current.noArchivedCustomers,
        message: S.current.archivedAppearHere,
      );
    }
    return EmptyState(
      icon: Icons.people_outline,
      title: S.current.noCustomersYet,
      message: S.current.addFirstCustomer,
      actionLabel: S.current.addCustomer,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: context.pal.brand,
                child: Text(
                  customer.initial,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: context.pal.slate500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.phone.isEmpty
                                ? S.current.noPhoneNumber
                                : customer.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.pal.slate500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.pal.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: context.pal.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}