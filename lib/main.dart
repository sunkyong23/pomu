import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/pomu_theme.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/in_app_purchase_service.dart';
import 'services/purchase_access_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PurchaseAccessService.instance.initialize();
  await InAppPurchaseService.instance.initialize();

  runApp(const PomuApp());
}

class PomuApp extends StatelessWidget {
  const PomuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;

    debugPrint('🌍 iOS locale: $platformLocale');
    debugPrint(
      '🌍 iOS locales: '
      '${WidgetsBinding.instance.platformDispatcher.locales}',
    );
    return MaterialApp(
      onGenerateTitle: (context) {
        return AppLocalizations.of(context).appName;
      },
      debugShowCheckedModeBanner: false,
      theme: PomuTheme.light(),
      supportedLocales: AppLocalizations.supportedLocales,

      localeResolutionCallback: (locale, supportedLocales) {
        debugPrint('🌍 Requested locale: $locale');

        if (locale != null) {
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              debugPrint('🌍 Resolved locale: $supportedLocale');
              return supportedLocale;
            }
          }
        }

        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
