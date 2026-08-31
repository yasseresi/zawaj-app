import 'package:zawaj_app/src/imports/imports.dart';

/// First-run carousel (3 slides), Arabic-first RTL. "Skip" and the final CTA
/// both route to login. Uses [SmoothPageIndicator] for the dots.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    (icon: Icons.checklist_rtl_rounded, key: 1),
    (icon: Icons.groups_2_outlined, key: 2),
    (icon: Icons.mark_email_read_outlined, key: 3),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  void _next() {
    if (_isLast) {
      context.go(AppRoutes.login);
    } else {
      _controller.nextPage(duration: AppDurations.normal, curve: AppCurves.standard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text('onboarding.skip'.tr(),
                    style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.xl.w),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 96.sp, color: cs.primary),
                        ),
                        SizedBox(height: AppSpacing.xxl.h),
                        Text('onboarding.title_${s.key}'.tr(),
                            textAlign: TextAlign.center,
                            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: AppSpacing.md.h),
                        Text('onboarding.subtitle_${s.key}'.tr(),
                            textAlign: TextAlign.center,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.xl.w),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _slides.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: cs.primary,
                      dotColor: cs.outlineVariant,
                      dotHeight: 8.h,
                      dotWidth: 8.w,
                      expansionFactor: 3,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  AppButton(
                    label: _isLast ? 'onboarding.get_started'.tr() : 'onboarding.next'.tr(),
                    isFullWidth: true,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
