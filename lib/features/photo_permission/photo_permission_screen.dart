import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../../services/photo_permission_service.dart';
import '../home/home_screen.dart';

class PhotoPermissionScreen extends StatefulWidget {
  const PhotoPermissionScreen({super.key});

  @override
  State<PhotoPermissionScreen> createState() => _PhotoPermissionScreenState();
}

class _PhotoPermissionScreenState extends State<PhotoPermissionScreen> {
  final PhotoPermissionService _permissionService = PhotoPermissionService();

  bool _isLoading = false;

  Future<void> _requestPermission() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final PermissionState state = await _permissionService.requestPermission();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (state.hasAccess) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }

    await _showPermissionDialog();
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '사진 접근 권한이 필요해요',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          content: const Text(
            '중복 사진을 찾고 저장공간을 정리하려면 '
            '사진 보관함 접근 권한이 필요해요.\n\n'
            '사진은 기기 안에서만 처리되며 '
            '외부 서버로 업로드되지 않아요.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: PomuColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('나중에'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _permissionService.openSettings();
              },
              child: const Text('설정 열기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PomuSpacing.lg,
            vertical: PomuSpacing.lg,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),

              const PomuLogo(size: 88),

              const SizedBox(height: PomuSpacing.xl),

              const Text(
                '사진을 더 깔끔하게\n정리해드릴게요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.7,
                  height: 1.18,
                ),
              ),

              const SizedBox(height: PomuSpacing.md),

              const Text(
                '중복 사진과 불필요한 사진을 찾아\n'
                '아이폰 저장공간을 쉽게 확보할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: PomuColors.textSecondary,
                ),
              ),

              const SizedBox(height: PomuSpacing.xl),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PomuSpacing.md),
                decoration: BoxDecoration(
                  color: PomuColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PomuColors.divider),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PrivacyIcon(),
                    SizedBox(width: PomuSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '사진은 안전하게 처리돼요',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: PomuColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '사진은 기기 안에서만 분석되며\n'
                            '외부 서버로 업로드되지 않아요.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: PomuColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              PomuPrimaryButton(
                text: '사진 정리 시작하기',
                icon: Icons.photo_library_outlined,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _requestPermission,
              ),

              const SizedBox(height: PomuSpacing.md),

              const Text(
                '권한은 언제든 아이폰 설정에서 변경할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: PomuColors.textSecondary),
              ),

              const SizedBox(height: PomuSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyIcon extends StatelessWidget {
  const _PrivacyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: PomuColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        size: 22,
        color: PomuColors.primary,
      ),
    );
  }
}
