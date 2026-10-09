import '../../imports/core_imports.dart';

/// The app's [EasyLocalization] setup (used by `main` and the i18n tests, so
/// tests render with the shipped settings).
class LocalizationWrapper extends StatelessWidget {
  final Widget child;

  /// Arabic-first (RTL) by default.
  final Locale startLocale;

  const LocalizationWrapper({
    super.key,
    required this.child,
    this.startLocale = const Locale('ar'),
  });

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      startLocale: startLocale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('fr'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      // Use each language's CLDR plural rules (Arabic few/many, etc.); the
      // default only distinguishes zero/one/two/other. Counts of 0 go
      // through pluralOrZero so authored zero forms still win.
      ignorePluralRules: false,
      child: child,
    );
  }
}
