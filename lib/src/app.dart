import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/shared/providers/theme_provider.dart';

/// Brand seed (terracotta) from the Zawaj design system. Drives both light and
/// dark [ColorScheme]s via `ColorScheme.fromSeed`.
const String kBrandPrimaryHex = '#C9796A';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil baseline matches DESIGN.md (390×844, iPhone-14 class).
    return ScreenUtilWrapper(
      designSize: const Size(390, 844),
      child: _buildMaterialApp(context),
    );
  }

  Widget _buildMaterialApp(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp.router(
      title: 'Zawaj',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: kBrandPrimaryHex),
      darkTheme: buildDarkTheme(primaryColorHex: kBrandPrimaryHex),
      themeMode: themeMode,
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        current = SessionListenerWrapper(child: current);
        return current;
      },
    );
  }
}
