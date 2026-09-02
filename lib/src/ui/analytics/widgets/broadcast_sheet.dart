import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:zawaj_app/src/core/i18n/locale_keys.g.dart';
import '../../../extensions/context_extension.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.all(24),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = context.appColors;

    TextStyle titleStyle() => TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
          fontFamily: 'serif',
        );
    TextStyle descStyle() => TextStyle(fontSize: 14, color: cs.onSurfaceVariant);

    ButtonStyle primaryBtn() => ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
    ButtonStyle cancelBtn() => OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );

    switch (state) {
      case BroadcastState.confirm:
      case BroadcastState.sending:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(LocaleKeys.analytics_broadcast_confirm_title.tr(), style: titleStyle()),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.analytics_broadcast_confirm_desc.tr(
                namedArgs: {'count': '$pendingCount'},
              ),
              style: descStyle(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: state == BroadcastState.sending ? null : onCancel,
                  style: cancelBtn(),
                  child: Text(LocaleKeys.analytics_cancel.tr()),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: state == BroadcastState.sending ? null : onConfirm,
                  style: primaryBtn(),
                  child: state == BroadcastState.sending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
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
              decoration: BoxDecoration(
                color: ac.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: ac.success, size: 32),
            ),
            const SizedBox(height: 16),
            Text(LocaleKeys.analytics_broadcast_success_title.tr(), style: titleStyle()),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.analytics_broadcast_success_desc.tr(
                namedArgs: {'count': '$count'},
              ),
              textAlign: TextAlign.center,
              style: descStyle(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: primaryBtn(),
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
            Text(LocaleKeys.analytics_broadcast_error_title.tr(), style: titleStyle()),
            const SizedBox(height: 12),
            Text(LocaleKeys.analytics_broadcast_error_desc.tr(), style: descStyle()),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: cancelBtn(),
                  child: Text(LocaleKeys.analytics_cancel.tr()),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: primaryBtn(),
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
