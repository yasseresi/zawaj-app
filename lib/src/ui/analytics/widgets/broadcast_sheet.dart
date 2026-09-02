import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:zawaj_app/src/core/i18n/locale_keys.g.dart';
import '../providers/analytics_provider.dart';

class BroadcastSheet extends StatelessWidget {
  const BroadcastSheet({
    super.key,
    required this.state,
    required this.pendingCount,
    required this.sentCount,
    required this.onConfirm,
    required this.onCancel,
    required this.onDismiss,
  });

  final BroadcastState state;
  final int pendingCount;
  final int sentCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (state == BroadcastState.idle) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          padding: const EdgeInsets.all(24),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state) {
      case BroadcastState.confirm:
      case BroadcastState.sending:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.analytics_broadcast_confirm_title.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.analytics_broadcast_confirm_desc.tr(
                namedArgs: {'count': '$pendingCount'},
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: state == BroadcastState.sending ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF334155)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(LocaleKeys.analytics_cancel.tr()),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: state == BroadcastState.sending ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A598),
                    foregroundColor: const Color(0xFF2A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state == BroadcastState.sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A1A1A)),
                          ),
                        )
                      : Text(
                          LocaleKeys.analytics_send.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        );

      case BroadcastState.success:
        final count = sentCount > 0 ? sentCount : pendingCount;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0x335E8C61),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF7ABF7E),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.analytics_broadcast_success_title.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.analytics_broadcast_success_desc.tr(
                namedArgs: {'count': '$count'},
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A598),
                  foregroundColor: const Color(0xFF2A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  LocaleKeys.analytics_ok.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case BroadcastState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.analytics_broadcast_error_title.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.analytics_broadcast_error_desc.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF334155)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(LocaleKeys.analytics_cancel.tr()),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A598),
                    foregroundColor: const Color(0xFF2A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.analytics_retry.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        );

      case BroadcastState.idle:
        return const SizedBox.shrink();
    }
  }
}
