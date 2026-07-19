import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/pomu_theme.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/in_app_purchase_service.dart';
import 'services/purchase_access_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 로컬에 저장된 구매 접근 상태는 앱 실행 전에 먼저 불러옵니다.
  await PurchaseAccessService.instance.initialize();

  // 첫 화면을 먼저 표시합니다.
  runApp(const PomuApp());

  // StoreKit 연결과 상품 조회는 앱 실행을 막지 않도록 백그라운드에서 진행합니다.
  unawaited(_initializeStoreKit());
}

Future<void> _initializeStoreKit() async {
  try {
    await InAppPurchaseService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('⚠️ StoreKit initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
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
