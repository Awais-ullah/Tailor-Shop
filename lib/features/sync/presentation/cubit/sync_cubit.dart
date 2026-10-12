import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/features/sync/data/sync_repository.dart';

enum SyncStatus { connecting, synced, syncing, offline }

class SyncState extends Equatable {
  const SyncState({this.status = SyncStatus.connecting});

  final SyncStatus status;

  @override
  List<Object?> get props => [status];
}

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(SyncRepository repository, {required String shopId})
      : super(const SyncState()) {
    final streams = repository.watchMetadata(shopId);
    _expected = streams.length;

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      _subscriptions.add(
        streams[index].listen(
              (metadata) {
            _latest[index] = metadata;
            _recompute();
          },
          // Permission or network errors are shown by the screens that
          // own the data; this indicator just stays quiet.
          onError: (Object _) {},
        ),
      );
    }
  }

  late final int _expected;
  final Map<int, SnapshotMetadata> _latest = {};
  final List<StreamSubscription<SnapshotMetadata>> _subscriptions = [];
  Timer? _debounce;
  SyncStatus? _candidate;

  void _recompute() {
    // Wait until every collection has reported at least once.
    if (_latest.length < _expected) return;

    final fromCache = _latest.values.any((m) => m.isFromCache);
    final pending = _latest.values.any((m) => m.hasPendingWrites);

    final raw = fromCache
        ? SyncStatus.offline
        : (pending ? SyncStatus.syncing : SyncStatus.synced);

    // Already showing, or already waiting to show, this status.
    if (raw == _candidate) return;
    _candidate = raw;
    _debounce?.cancel();

    if (raw == SyncStatus.synced) {
      _set(raw);
      return;
    }

    // Right after launch the cache answers first, and a normal online save
    // is "pending" for a split second. Wait before alarming anyone.
    final delay = raw == SyncStatus.offline
        ? const Duration(seconds: 3)
        : const Duration(milliseconds: 1500);
    _debounce = Timer(delay, () => _set(raw));
  }

  void _set(SyncStatus status) {
    if (state.status != status) emit(SyncState(status: status));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    return super.close();
  }
}