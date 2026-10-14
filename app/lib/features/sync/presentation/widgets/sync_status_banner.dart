import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        if (state.pendingCount == 0 && state is! SyncInProgress) {
          return const SizedBox.shrink();
        }

        final isSyncing = state is SyncInProgress;

        return Container(
          width: double.infinity,
          color: AppColors.stateOffline.withOpacity(0.15),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space8,
          ),
          child: Row(
            children: [
              Icon(
                isSyncing ? Icons.sync : Icons.cloud_queue_rounded,
                size: 18,
                color: AppColors.stateOffline,
              ),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: Text(
                  isSyncing
                      ? 'Menyinkronkan ${state.pendingCount} data ke server...'
                      : 'Mode Offline: ${state.pendingCount} data tersimpan lokal.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textWhitePrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!isSyncing)
                TextButton(
                  onPressed: () {
                    context.read<SyncBloc>().add(TriggerSyncEvent());
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Sinkronkan',
                    style: TextStyle(
                      color: AppColors.neonVolt,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
