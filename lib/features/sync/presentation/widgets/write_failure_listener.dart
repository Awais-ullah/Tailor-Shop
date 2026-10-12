import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/write_failures.dart';

/// Shows one dialog when a saved change is rejected by the server.
class WriteFailureListener extends StatefulWidget {
  const WriteFailureListener({super.key, required this.child});

  final Widget child;

  @override
  State<WriteFailureListener> createState() => _WriteFailureListenerState();
}

class _WriteFailureListenerState extends State<WriteFailureListener> {
  StreamSubscription<String>? _subscription;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _subscription = WriteFailures.stream.listen(_onFailure);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _onFailure(String message) async {
    // One dialog at a time is enough to get the user's attention.
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.sync_problem, color: AppColors.danger),
        title: const Text("A change couldn't be saved"),
        content: Text(
          '$message\n\nThe change was undone on this device. Please check '
              'your data and try again.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}