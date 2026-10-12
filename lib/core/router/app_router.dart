import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/router/go_router_refresh_stream.dart';
import 'package:tailor_app/core/router/splash_gate.dart';
// import 'package:tailor_app/features/shop/presentation/widgets/shop_debug_tile.dart';
import 'package:tailor_app/features/dashboard/presentation/screens/dashboard_screen.dart';

import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:tailor_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tailor_app/features/auth/presentation/screens/login_screen.dart';
import 'package:tailor_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:tailor_app/features/auth/presentation/screens/splash_screen.dart';

import 'package:tailor_app/features/more/presentation/screens/more_screen.dart';
import 'package:tailor_app/features/shell/presentation/screens/app_shell.dart';

import '../../features/customers/presentation/screens/customer_form_screen.dart';
import '../../features/customers/presentation/screens/customer_profile_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/measurements/data/measurement_templates.dart';
import '../../features/measurements/presentation/screens/measurement_detail_screen.dart';
import '../../features/measurements/presentation/screens/measurement_form_screen.dart';
import '../../features/measurements/presentation/screens/measurements_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_form_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/payments/presentation/screens/customer_ledger_screen.dart';
import '../../features/payments/presentation/screens/ledger_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/widgets/app_providers.dart';

/// Builds the router. It needs the AuthCubit so it can redirect users
/// based on whether they are logged in.
///
/// IMPORTANT: the order of the shell branches must match the `branchIndex`
/// values in lib/features/shell/presentation/screens/app_shell.dart.
GoRouter buildAppRouter(AuthCubit authCubit) {
  final splashGate = SplashGate();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    // Re-run `redirect` whenever the login status changes.
    refreshListenable: Listenable.merge([
      splashGate,
      GoRouterRefreshStream(
        authCubit.stream.map((state) => state.status).distinct(),
      ),
    ]),
    redirect: (context, state) {
      final status = authCubit.state.status;
      final location = state.matchedLocation;
      final isSplash = location == AppRoutes.splash;
      final isAuthRoute = AppRoutes.authRoutes.contains(location);

      // Stay on the splash until its animation has finished.
      if (!splashGate.isOpen) return isSplash ? null : AppRoutes.splash;

      switch (status) {
        case AuthStatus.unknown:
          return isSplash ? null : AppRoutes.splash;
        case AuthStatus.unauthenticated:
          return isAuthRoute ? null : AppRoutes.login;
        case AuthStatus.authenticated:
          return (isAuthRoute || isSplash) ? AppRoutes.dashboard : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashScreen(gate: splashGate),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppProviders(
          child: AppShell(navigationShell: navigationShell),
        ),
        branches: [
          // 0
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          // 1
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.customers,
              builder: (context, state) => const CustomersScreen(),
              routes: [
                // 'new' must come BEFORE ':id', otherwise "new" would be
                // treated as a customer id.
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const CustomerFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => CustomerProfileScreen(
                    customerId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => CustomerFormScreen(
                        customerId: state.pathParameters['id'],
                      ),
                    ),
                    // 'measurements/new' must come BEFORE 'measurements/:mid'.
                    GoRoute(
                      path: 'measurements/new',
                      builder: (context, state) => MeasurementFormScreen(
                        customerId: state.pathParameters['id'],
                        garmentType: GarmentType.fromId(
                          state.uri.queryParameters['garment'],
                        ),
                      ),
                    ),
                    GoRoute(
                      path: 'measurements/:mid',
                      builder: (context, state) => MeasurementDetailScreen(
                        measurementId: state.pathParameters['mid']!,
                        editLocation: AppRoutes.customerMeasurementEdit(
                          state.pathParameters['id']!,
                          state.pathParameters['mid']!,
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) => MeasurementFormScreen(
                            measurementId: state.pathParameters['mid'],
                          ),
                        ),
                      ],
                    ),
                    // 'orders/new' must come BEFORE 'orders/:oid'.
                    GoRoute(
                      path: 'orders/new',
                      builder: (context, state) => OrderFormScreen(
                        customerId: state.pathParameters['id'],
                      ),
                    ),
                    GoRoute(
                      path: 'orders/:oid',
                      builder: (context, state) => OrderDetailScreen(
                        orderId: state.pathParameters['oid']!,
                        editLocation: AppRoutes.customerOrderEdit(
                          state.pathParameters['id']!,
                          state.pathParameters['oid']!,
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) => OrderFormScreen(
                            orderId: state.pathParameters['oid'],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ]),
          // 2
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.measurements,
              builder: (context, state) => const MeasurementsScreen(),
              routes: [
                // 'new' must come BEFORE ':mid'.
                GoRoute(
                  path: 'new',
                  builder: (context, state) => MeasurementFormScreen(
                    customerId: state.uri.queryParameters['customerId'],
                    garmentType: GarmentType.fromId(
                      state.uri.queryParameters['garment'],
                    ),
                  ),
                ),
                GoRoute(
                  path: ':mid',
                  builder: (context, state) => MeasurementDetailScreen(
                    measurementId: state.pathParameters['mid']!,
                    editLocation:
                    AppRoutes.measurementEdit(state.pathParameters['mid']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => MeasurementFormScreen(
                        measurementId: state.pathParameters['mid'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          // 3
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.orders,
              builder: (context, state) => const OrdersScreen(),
              routes: [
                // 'new' must come BEFORE ':oid'.
                GoRoute(
                  path: 'new',
                  builder: (context, state) => OrderFormScreen(
                    customerId: state.uri.queryParameters['customerId'],
                  ),
                ),
                GoRoute(
                  path: ':oid',
                  builder: (context, state) => OrderDetailScreen(
                    orderId: state.pathParameters['oid']!,
                    editLocation:
                    AppRoutes.orderEdit(state.pathParameters['oid']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => OrderFormScreen(
                        orderId: state.pathParameters['oid'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          // 4
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.ledger,
              builder: (context, state) => const LedgerScreen(),
              routes: [
                GoRoute(
                  path: ':customerId',
                  builder: (context, state) => CustomerLedgerScreen(
                    customerId: state.pathParameters['customerId']!,
                  ),
                ),
              ],
            ),
          ]),
          // 5
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.reports,
              builder: (context, state) => const ReportsScreen(),
            ),
          ]),
          // 6
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
          // 7 (mobile "More" menu)
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.more,
              builder: (context, state) => const MoreScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}