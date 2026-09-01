import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/guest_model.dart';

/// Mockup screen 7 "edit status" sheet: three RSVP options (icon + title + desc)
/// with the current one preselected, and a save button. Pops the chosen
/// [RsvpStatus] (or null on cancel). Present via [showAppSheet].
class EditStatusSheet extends StatefulWidget {
  const EditStatusSheet({super.key, required this.current});

  final RsvpStatus current;

  @override
  State<EditStatusSheet> createState() => _EditStatusSheetState();
}

class _EditStatusSheetState extends State<EditStatusSheet> {
  late RsvpStatus _selected = widget.current;

  static const _order = [
    RsvpStatus.confirmed,
    RsvpStatus.pending,
    RsvpStatus.declined,
  ];

  static (Color, IconData, String, String) _spec(RsvpStatus s) => switch (s) {
        RsvpStatus.confirmed => (
            const Color(0xFF2E7D5B),
            Icons.check_circle_outline,
            'guests.status_confirmed'.tr(),
            'guests.status_confirmed_desc'.tr(),
          ),
        RsvpStatus.pending => (
            const Color(0xFFB8860B),
            Icons.schedule,
            'guests.status_pending'.tr(),
            'guests.status_pending_desc'.tr(),
          ),
        RsvpStatus.declined => (
            const Color(0xFFC84B3A),
            Icons.cancel_outlined,
            'guests.status_declined'.tr(),
            'guests.status_declined_desc'.tr(),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppBorders.bottomSheet,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg.w,
        right: AppSpacing.lg.w,
        top: AppSpacing.sm.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: AppSpacing.md.h),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            'guests.edit_status_title'.tr(),
            style: context.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.lg.h),
          for (final s in _order) ...[
            _StatusOption(
              spec: _spec(s),
              selected: s == _selected,
              onTap: () => setState(() => _selected = s),
            ),
            SizedBox(height: AppSpacing.sm.h),
          ],
          SizedBox(height: AppSpacing.sm.h),
          AppButton(
            label: 'guests.save_status'.tr(),
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final (Color, IconData, String, String) spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon, title, desc) = spec;
    final tt = context.textTheme;
    final cs = context.colors;

    return Material(
      color: selected ? color.withValues(alpha: 0.10) : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 2.h),
                    Text(desc,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check, color: color, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}
