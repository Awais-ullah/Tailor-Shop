import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// A slim strip that only appears when something needs attention.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        Color? color;
        IconData? icon;
        String? text;

        switch (state.status) {
          case SyncStatus.offline:
            color = context.pal.warning;
            icon = Icons.cloud_off_outlined;
            text = S.current.offlineBanner;
          case SyncStatus.syncing:
            color = context.pal.info;
            icon = Icons.sync;
            text = S.current.syncingChanges;
          case SyncStatus.connecting:
          case SyncStatus.synced:
            break;
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.bottomCenter,
          child: color == null
              ? const SizedBox(width: double.infinity)
              : Container(
            width: double.infinity,
            color: color.withValues(alpha: 0.14),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}