import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/customers/data/repositories/customer_repository.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/measurements/data/repositories/measurement_repository.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_cubit.dart';
import 'package:tailor_app/features/orders/data/repositories/order_repository.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/payments/data/repositories/payment_repository.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:tailor_app/features/sync/data/sync_repository.dart';
import 'package:tailor_app/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:tailor_app/features/sync/presentation/widgets/write_failure_listener.dart';

/// Providers that only exist while someone is logged in.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthCubit cubit) => cubit.state.user?.uid);

    // Only briefly true while signing out; the router redirects away.
    if (uid == null) return const SizedBox.shrink();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CustomerRepository>(
          create: (_) => CustomerRepository(),
        ),
        RepositoryProvider<MeasurementRepository>(
          create: (_) => MeasurementRepository(),
        ),
        RepositoryProvider<OrderRepository>(
          create: (_) => OrderRepository(),
        ),
        RepositoryProvider<PaymentRepository>(
          create: (_) => PaymentRepository(),
        ),
        RepositoryProvider<SyncRepository>(
          create: (_) => SyncRepository(),
        ),
      ],
      child: MultiBlocProvider(
        // A different user signing in gets brand-new cubits.
        key: ValueKey(uid),
        providers: [
          BlocProvider<CustomersCubit>(
            create: (context) => CustomersCubit(
              context.read<CustomerRepository>(),
              shopId: uid,
            ),
          ),
          BlocProvider<MeasurementsCubit>(
            create: (context) => MeasurementsCubit(
              context.read<MeasurementRepository>(),
              shopId: uid,
            ),
          ),
          BlocProvider<OrdersCubit>(
            create: (context) => OrdersCubit(
              context.read<OrderRepository>(),
              shopId: uid,
            ),
          ),
          BlocProvider<PaymentsCubit>(
            create: (context) => PaymentsCubit(
              context.read<PaymentRepository>(),
              shopId: uid,
            ),
          ),
          BlocProvider<SyncCubit>(
            create: (context) => SyncCubit(
              context.read<SyncRepository>(),
              shopId: uid,
            ),
          ),
        ],
        child: WriteFailureListener(child: child),
      ),
    );
  }
}