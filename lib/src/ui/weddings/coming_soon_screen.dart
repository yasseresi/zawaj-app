import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

/// Placeholder for Phase-2 weddings slices not yet built (create wedding,
/// wedding detail / guest list). Registered so navigation from the home list is
/// live; replaced screen-by-screen as each slice lands.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handyman_outlined, size: 56.sp, color: cs.onSurfaceVariant),
              SizedBox(height: AppSpacing.md.h),
              Text('weddings.coming_soon'.tr(),
                  textAlign: TextAlign.center, style: context.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
