import '../../imports/imports.dart';

/// Displays an error state with an icon, title, optional body, and retry button.
///
/// Usage:
/// ```dart
/// AppErrorWidget(
///   title: 'Something went wrong',
///   message: error.toString(),
///   onRetry: () => ref.invalidate(myProvider),
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.error_outline_rounded,
    this.compact = false,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final dynamic icon;

  /// Smaller icon/padding for inline banners above stale content.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final iconSize = compact ? 40.0 : 56.0;
    final titleStyle = compact
        ? tt.titleSmall?.copyWith(
            color: cs.onSurface, fontWeight: FontWeight.w600)
        : tt.titleMedium?.copyWith(
            color: cs.onSurface, fontWeight: FontWeight.bold);
    final bodyStyle = tt.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final pad = compact ? 16.0 : 32.0;

    final content = Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon: icon, size: iconSize, color: cs.error),
          SizedBox(height: compact ? 8 : 16),
          Text(
            title,
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            SizedBox(height: compact ? 4 : 8),
            Text(
              message!,
              style: bodyStyle,
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: compact ? 12 : 24),
            AppButton(
              label: retryLabel ?? 'actions.retry'.tr(),
              onPressed: onRetry,
              variant: ButtonVariant.outline,
            ),
          ],
        ],
      ),
    );

    return compact ? content : Center(child: content);
  }
}
