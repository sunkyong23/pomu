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

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('사진 접근 권한이 필요해요'),
          content: const Text(
            '사진을 자동으로 정리하려면 사진 접근 권한이 필요해요. 설정에서 권한을 허용해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _permissionService.openSettings();
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
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const PomuLogo(size: 88),
              const SizedBox(height: PomuSpacing.xl),
              const Text(
                '사진을 정리하려면\n권한이 필요해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: PomuSpacing.sm),
              const Text(
                '새 사진을 자동으로 분석하고\n앨범별로 정리해드려요.',
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
                isLoading: _isLoading,
                onPressed: _requestPermission,
              ),
              const SizedBox(height: PomuSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
