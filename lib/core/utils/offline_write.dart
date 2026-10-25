import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/errors/firestore_error_mapper.dart';
import 'package:tailor_app/core/utils/write_failures.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// Offline-first write helper.
///
/// A Firestore write's Future only completes when the SERVER confirms it.
/// Offline, that can take hours. So we wait briefly: quick failures
/// (like permission errors) are reported straight away. If the server has
/// not answered within [grace], the write stays safely queued on the
/// device and we carry on. If the server REJECTS it later, the user is
/// told through [WriteFailures].
Future<void> awaitWriteBriefly(
    Future<void> write, {
      Duration grace = const Duration(seconds: 1),
    }) async {
  try {
    await write.timeout(grace);
  } on TimeoutException {
    unawaited(
      write.then<void>(
            (_) {},
        onError: (Object error) {
          debugPrint('[Firestore write] rejected later: $error');
          WriteFailures.report(
            error is FirebaseException
                ? FirestoreErrorMapper.message(error.code)
                : S.current.errorSaving,
          );
        },
      ),
    );
  } on FirebaseException catch (e) {
    debugPrint('[Firestore write] ${e.code}: ${e.message}');
    throw AppFailure(FirestoreErrorMapper.message(e.code));
  }
}