import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_router.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_theme.dart';
import 'package:tailor_app/features/auth/data/repositories/auth_repository.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/shop/data/repositories/shop_repository.dart';
import 'package:tailor_app/features/shop/data/shop_bootstrapper.dart';
import 'package:tailor_app/firebase_options.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the phone's splash on screen until our splash is ready to take over.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Technical details go to the log. Users never see raw errors.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[Unhandled error] $error\n$stack');
    return true;
  };
  if (kReleaseMode) {
    // A calm message instead of the red error screen.
    ErrorWidget.builder = (FlutterErrorDetails details) => const _FriendlyError();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline persistence. This must run before any other Firestore call.
  // Unlimited cache so the shop's data is never evicted to save space.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const TailorShopApp());
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Something went wrong on this screen.\nPlease go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate700, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

class TailorShopApp extends StatefulWidget {
  const TailorShopApp({super.key});

  @override
  State<TailorShopApp> createState() => _TailorShopAppState();
}

class _TailorShopAppState extends State<TailorShopApp> {
  // Created once, so the router and login state survive rebuilds.
  late final AuthRepository _authRepository;
  late final ShopRepository _shopRepository;
  late final AuthCubit _authCubit;
  late final ShopBootstrapper _shopBootstrapper;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _shopRepository = ShopRepository();
    _authCubit = AuthCubit(_authRepository);
    _shopBootstrapper = ShopBootstrapper(
      authCubit: _authCubit,
      shopRepository: _shopRepository,
    );
    _router = buildAppRouter(_authCubit);
  }

  @override
  void dispose() {
    _router.dispose();
    _shopBootstrapper.dispose();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<ShopRepository>.value(value: _shopRepository),
      ],
      child: BlocProvider.value(
        value: _authCubit,
        child: MaterialApp.router(
          title: 'Tailor Shop',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          // Keeps layouts intact when a phone's font size is set very large,
          // while still respecting the user's text size up to 150%.
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.5,
            child: child!,
          ),
        ),
      ),
    );
  }
}