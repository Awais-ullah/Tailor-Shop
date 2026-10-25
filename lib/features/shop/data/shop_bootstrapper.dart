import 'dart:async';

import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:tailor_app/features/shop/data/repositories/shop_repository.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// Watches the login state and makes sure a logged-in owner has a shop
/// document. Runs in the background; nothing waits for it.
class ShopBootstrapper {
  ShopBootstrapper({
    required AuthCubit authCubit,
    required this._shopRepository,
  }) {
    _handle(authCubit.state);
    _subscription = authCubit.stream.listen(_handle);
  }

  final ShopRepository _shopRepository;
  late final StreamSubscription<AuthState> _subscription;
  String? _lastUid;

  void _handle(AuthState state) {
    final user = state.user;

    if (state.status != AuthStatus.authenticated || user == null) {
      _lastUid = null;
      return;
    }
    if (user.uid == _lastUid) return;
    _lastUid = user.uid;

    final owner = user.displayName?.trim() ?? '';
    final shopName = owner.isEmpty ? S.current.myTailorShop : S.current.ownersTailorShop(owner);

    unawaited(
      _shopRepository.ensureShopExists(ownerUid: user.uid, shopName: shopName),
    );
  }

  Future<void> dispose() => _subscription.cancel();
}