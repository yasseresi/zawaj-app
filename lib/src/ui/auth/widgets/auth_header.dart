import 'package:zawaj_app/src/imports/imports.dart';

/// Brand lockup for the auth screens: the زواج wordmark (gold), a rings glyph,
/// and the latin "ZAWAJ" subtitle — mirrors the mockup's auth header.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return Column(
      children: [
        Icon(Icons.favorite_rounded, color: cs.primary, size: 40.sp),
        SizedBox(height: AppSpacing.sm.h),
        Text(
          'app_name'.tr(),
          style: tt.displaySmall?.copyWith(
            color: context.appColors.warning,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'ZAWAJ',
          style: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
