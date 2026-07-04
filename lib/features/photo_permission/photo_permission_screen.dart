import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../home/home_screen.dart';

class PhotoPermissionScreen extends StatelessWidget {
  const PhotoPermissionScreen({super.key});

  void _goHome(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const PomuLogo(size: 88),
              const SizedBox(height: PomuSpacing.xl),
              const Text(
                '사진 접근 권한이 필요해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: PomuSpacing.sm),
              const Text(
                'Pomu가 새 사진을 찾고 자동으로 정리하려면\n사진 보관함 접근이 필요해요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: PomuColors.textSecondary,
                ),
              ),
              const Spacer(),
              PomuPrimaryButton(
                text: '사진 접근 허용하기',
                icon: Icons.photo_library_outlined,
                onPressed: () => _goHome(context),
              ),
              const SizedBox(height: PomuSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
