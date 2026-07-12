import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../duplicates/duplicate_candidates_screen.dart';
import '../settings/settings_screen.dart';

import '../../services/duplicate_summary_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DuplicateSummaryService _summaryService = DuplicateSummaryService();

  DuplicateSummary _summary = const DuplicateSummary.empty();
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summary = await _summaryService.loadSummary();

    if (!mounted) return;

    setState(() {
      _summary = summary;
      _isLoadingSummary = false;
    });
  }

  Future<void> _openDuplicateCleanup(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DuplicateCandidatesScreen()),
    );

    if (!mounted) return;
    await _loadSummary();
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

    if (!mounted) return;

    await _loadSummary();
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$featureName 기능은 준비 중이에요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: PomuColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0MB';

    final mb = bytes / (1024 * 1024);

    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)}MB';
    }

    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)}GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PomuSpacing.lg,
            PomuSpacing.md,
            PomuSpacing.lg,
            PomuSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(onSettingsPressed: () => _openSettings(context)),
              const SizedBox(height: PomuSpacing.xxl),

              const Text(
                '아이폰 사진을 정리하고\n저장공간을 되찾아보세요',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                  height: 1.16,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: PomuSpacing.md),

              const Text(
                '비슷하거나 필요 없는 사진을 찾아\n안전하게 정리할 수 있어요.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: PomuColors.textSecondary,
                ),
              ),
              const SizedBox(height: PomuSpacing.xl),

              _MainCleanupCard(
                isLoading: _isLoadingSummary,
                summary: _summary,
                readableSize: _formatBytes(_summary.reclaimableBytes),
                onTap: () => _openDuplicateCleanup(context),
              ),
              const SizedBox(height: PomuSpacing.xxl),

              const Text(
                '정리 도구',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: PomuSpacing.md),

              _CleanupToolCard(
                icon: Icons.blur_on_rounded,
                title: '흐릿한 사진',
                description: '초점이 흐리거나 흔들린 사진을 찾아요',
                statusText: '준비 중',
                onTap: () => _showComingSoon(context, '흐릿한 사진 정리'),
              ),
              const SizedBox(height: PomuSpacing.sm),

              _CleanupToolCard(
                icon: Icons.photo_camera_back_outlined,
                title: '비슷한 사진',
                description: '연속으로 찍은 사진 중 좋은 사진을 골라요',
                statusText: '준비 중',
                onTap: () => _showComingSoon(context, '비슷한 사진 정리'),
              ),
              const SizedBox(height: PomuSpacing.sm),

              _CleanupToolCard(
                icon: Icons.screenshot_rounded,
                title: '오래된 스크린샷',
                description: '오랫동안 보지 않은 스크린샷을 모아봐요',
                statusText: '준비 중',
                onTap: () => _showComingSoon(context, '스크린샷 정리'),
              ),
              const SizedBox(height: PomuSpacing.sm),

              _CleanupToolCard(
                icon: Icons.video_library_outlined,
                title: '대용량 동영상',
                description: '저장공간을 많이 차지하는 영상을 찾아요',
                statusText: '준비 중',
                onTap: () => _showComingSoon(context, '대용량 동영상 정리'),
              ),
              const SizedBox(height: PomuSpacing.sm),

              _CleanupToolCard(
                icon: Icons.motion_photos_on_outlined,
                title: 'Live Photo',
                description: '용량이 큰 Live Photo를 한곳에서 확인해요',
                statusText: '준비 중',
                onTap: () => _showComingSoon(context, 'Live Photo 정리'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onSettingsPressed;

  const _HomeHeader({required this.onSettingsPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PomuLogo(size: 32),
        const SizedBox(width: PomuSpacing.sm),
        const Text(
          'Pomu',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: PomuColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: '설정',
          onPressed: onSettingsPressed,
          icon: const Icon(
            Icons.settings_rounded,
            color: PomuColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MainCleanupCard extends StatelessWidget {
  final bool isLoading;
  final DuplicateSummary summary;
  final String readableSize;
  final VoidCallback onTap;

  const _MainCleanupCard({
    required this.isLoading,
    required this.summary,
    required this.readableSize,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(PomuSpacing.lg),
          decoration: BoxDecoration(
            color: PomuColors.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: PomuColors.primary.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.content_copy_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '지금 사용 가능',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PomuSpacing.xl),
              const Text(
                '중복 사진 정리',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: PomuSpacing.sm),
              if (isLoading)
                Text(
                  '중복 사진 정보를 불러오고 있어요.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                )
              else if (!summary.hasScanned)
                Text(
                  '아직 중복 사진을 확인하지 않았어요.\n첫 검사를 시작해보세요.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                )
              else if (summary.deleteCandidateCount == 0)
                Text(
                  '현재 정리할 중복 사진이 없어요.\n사진 보관함이 깔끔해요.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                )
              else
                Text(
                  '중복 후보 ${summary.groupCount}개 그룹 · '
                  '${summary.deleteCandidateCount}장\n'
                  '약 $readableSize의 공간을 확보할 수 있어요.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              const SizedBox(height: PomuSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: PomuSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      summary.hasScanned ? '다시 분석하기' : '중복 사진 찾아보기',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PomuColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: PomuColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CleanupToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusText;
  final VoidCallback onTap;

  const _CleanupToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(PomuSpacing.md),
          decoration: BoxDecoration(
            color: PomuColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PomuColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: PomuColors.primaryLight,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, size: 26, color: PomuColors.primary),
              ),
              const SizedBox(width: PomuSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: PomuColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: PomuSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PomuColors.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PomuColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: PomuColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: PomuSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: PomuColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
