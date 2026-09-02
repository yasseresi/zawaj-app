import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';

/// Centralized status color + label mapping for guest RSVP status.
///
/// Used by [GuestStatusPill], [EditStatusSheet], and history timeline dots.
/// Single source of truth — avoids drift across screens.
Color guestStatusColor(RsvpStatus s) => switch (s) {
      RsvpStatus.confirmed => const Color(0xFF2E7D5B),
      RsvpStatus.pending => const Color(0xFFB8860B),
      RsvpStatus.declined => const Color(0xFFC84B3A),
    };

String guestStatusLabel(RsvpStatus s) => switch (s) {
      RsvpStatus.confirmed => 'guests.status_confirmed'.tr(),
      RsvpStatus.pending => 'guests.status_pending'.tr(),
      RsvpStatus.declined => 'guests.status_declined'.tr(),
    };

String guestStatusDesc(RsvpStatus s) => switch (s) {
      RsvpStatus.confirmed => 'guests.status_confirmed_desc'.tr(),
      RsvpStatus.pending => 'guests.status_pending_desc'.tr(),
      RsvpStatus.declined => 'guests.status_declined_desc'.tr(),
    };

IconData guestStatusIcon(RsvpStatus s) => switch (s) {
      RsvpStatus.confirmed => Icons.check_circle_outline,
      RsvpStatus.pending => Icons.schedule,
      RsvpStatus.declined => Icons.cancel_outlined,
    };

/// Shared status pill widget showing RSVP status with consistent color/label.
///
/// [compact] makes it smaller for dense lists (guest list tile).
/// [showIcon] adds a leading icon (used in edit sheet options).
class GuestStatusPill extends StatelessWidget {
  const GuestStatusPill({
    super.key,
    required this.status,
    this.compact = false,
    this.showIcon = false,
  });

  final RsvpStatus status;
  final bool compact;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final color = guestStatusColor(status);
    final label = guestStatusLabel(status);
    final tt = context.textTheme;

    final hPadding = compact ? 8.w : 10.w;
    final vPadding = compact ? 3.h : 4.h;
    final fontSize = compact ? tt.labelSmall : tt.labelMedium;
    final iconSize = compact ? 14.sp : 16.sp;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(guestStatusIcon(status), color: color, size: iconSize),
            SizedBox(width: 4.w),
          ],
          Flexible(
            child: Text(
              label,
              style: fontSize?.copyWith(color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
