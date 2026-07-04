import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../core/widgets/logo/pomu_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  PomuLogo(size: 36),
                  SizedBox(width: PomuSpacing.sm),
                  Text(
                    'Pomu',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: PomuColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PomuSpacing.xxl),
              const Text(
                '사진 정리를\n시작해볼까요?',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                  height: 1.12,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: PomuSpacing.md),
              const Text(
                '새로 추가된 사진을 찾고,\nAI가 자동으로 분류해드릴게요.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: PomuColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PomuSpacing.lg),
                decoration: BoxDecoration(
                  color: PomuColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: PomuColors.divider),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: PomuColors.primary,
                      size: 30,
                    ),
                    SizedBox(height: PomuSpacing.md),
                    Text(
                      '새 사진을 발견하면',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: PomuColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: PomuSpacing.xs),
                    Text(
                      'Pomu가 카테고리별 앨범으로\n깔끔하게 정리해드려요.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: PomuColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PomuSpacing.xl),
              PomuPrimaryButton(
                text: '새 사진 찾기',
                icon: Icons.search_rounded,
                onPressed: () {
                  debugPrint('TODO: start photo scan');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
