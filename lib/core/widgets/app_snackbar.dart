import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';

class AppSnackbar {
  AppSnackbar._();

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.danger, Icons.error_outline);

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_outline);

  static void _show(
      BuildContext context,
      String message,
      Color color,
      IconData icon,
      ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }
}