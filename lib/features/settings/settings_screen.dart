import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../services/duplicate_history_service.dart';
import '../../services/duplicate_summary_service.dart';
import '../duplicates/duplicate_candidates_screen.dart';
import '../travel/create_travel_album_screen.dart';
import 'album_name_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openAlbumNameSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AlbumNameSettingsScreen()));
  }

  void _openCreateTravelAlbum(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateTravelAlbumScreen()));
  }

  void _openDuplicatePhotoScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DuplicateCandidatesScreen()),
    );
  }

  Future<void> _showClearDuplicateHistoryDialog(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: PomuColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '중복 정리 기록을 초기화할까요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          content: const Text(
            '이미 처리한 중복 후보가 다음 검사에서 다시 나타날 수 있어요.\n\n'
            '사진 자체가 삭제되거나 변경되지는 않아요.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: PomuColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PomuColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: PomuColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '초기화',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    await DuplicateHistoryService().clearResolvedGroups();
    await DuplicateSummaryService().clearSummary();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('중복 정리 기록을 초기화했어요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: PomuColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      appBar: AppBar(
        backgroundColor: PomuColors.background,
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(
            color: PomuColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(PomuSpacing.lg),
        children: [
          const Text(
            'Organize your memories,\nyour way.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
              height: 1.15,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: PomuSpacing.xl),

          _SettingsCard(
            icon: Icons.photo_album_rounded,
            title: '앨범 이름 설정',
            subtitle: '자동 생성될 앨범 이름을 직접 정할 수 있어요.',
            onTap: () => _openAlbumNameSettings(context),
          ),
          const SizedBox(height: PomuSpacing.md),

          _SettingsCard(
            icon: Icons.flight_takeoff_rounded,
            title: '여행 앨범 만들기',
            subtitle: '날짜를 선택해서 여행 사진을 앨범으로 묶어요.',
            onTap: () => _openCreateTravelAlbum(context),
          ),
          const SizedBox(height: PomuSpacing.md),

          _SettingsCard(
            icon: Icons.content_copy_rounded,
            title: '중복 사진 정리',
            subtitle: '비슷하거나 중복된 사진 후보를 확인해요.',
            onTap: () => _openDuplicatePhotoScreen(context),
          ),
          const SizedBox(height: PomuSpacing.md),

          _SettingsCard(
            icon: Icons.restart_alt_rounded,
            title: '중복 정리 기록 초기화',
            subtitle: '이미 처리한 중복 후보를 다시 볼 수 있어요.',
            onTap: () => _showClearDuplicateHistoryDialog(context),
          ),
          const SizedBox(height: PomuSpacing.md),

          const _SettingsCard(
            icon: Icons.auto_awesome_rounded,
            title: 'AI 분류 설정',
            subtitle: '준비 중이에요.',
          ),
          const SizedBox(height: PomuSpacing.md),

          const _SettingsCard(
            icon: Icons.language_rounded,
            title: '언어',
            subtitle: '준비 중이에요.',
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(PomuSpacing.lg),
        decoration: BoxDecoration(
          color: PomuColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: PomuColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PomuColors.primaryLight,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: enabled ? PomuColors.primary : PomuColors.textSecondary,
                size: 23,
              ),
            ),
            const SizedBox(width: PomuSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: enabled
                          ? PomuColors.textPrimary
                          : PomuColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: PomuColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: enabled ? PomuColors.textSecondary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
