import 'package:flutter/material.dart';

import 'core/theme/pomu_theme.dart';
import 'features/splash/splash_screen.dart';
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
    return MaterialApp(
      title: 'Pomu',
      debugShowCheckedModeBanner: false,
      theme: PomuTheme.light(),
      home: const SplashScreen(),
    );
  }
}
