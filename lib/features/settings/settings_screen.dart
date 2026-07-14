import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../services/duplicate_history_service.dart';
import '../../services/duplicate_result_cache_service.dart';
import '../../services/duplicate_summary_service.dart';
import 'album_name_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openAlbumNameSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AlbumNameSettingsScreen()));
  }

  Future<void> _showClearDuplicateResultDialog(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: PomuColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: const Text(
            '검사 결과를 초기화할까요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          content: const Text(
            '저장된 중복 그룹과 처리 완료 기록이 삭제돼요.\n\n'
            '다음 검사에서는 이전에 처리했던 그룹도 '
            '다시 나타날 수 있어요.\n\n'
            '아이폰 사진은 삭제되거나 변경되지 않아요.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: PomuColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PomuColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PomuColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
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

    try {
      await DuplicateResultCacheService().clearGroups();
      await DuplicateSummaryService().clearSummary();
      await DuplicateHistoryService().clearResolvedGroups();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('중복 사진 검사 결과를 초기화했어요.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: PomuColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('초기화하지 못했어요. 잠시 후 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      appBar: AppBar(
        backgroundColor: PomuColors.background,
        surfaceTintColor: PomuColors.background,
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(
            color: PomuColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PomuSpacing.lg,
          PomuSpacing.md,
          PomuSpacing.lg,
          PomuSpacing.xxl,
        ),
        children: [
          const _SettingsSectionHeader(
            title: '사진 정리',
            subtitle: '저장된 검사 결과를 관리해요.',
          ),

          const SizedBox(height: PomuSpacing.md),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.restart_alt_rounded,
                title: '중복 사진 검사 결과 초기화',
                subtitle: '저장된 결과와 처리 완료 기록을 지우고 다시 검사해요.',
                onTap: () {
                  _showClearDuplicateResultDialog(context);
                },
              ),
            ],
          ),

          const SizedBox(height: PomuSpacing.xl),

          const _SettingsSectionHeader(
            title: '앨범',
            subtitle: '자동 생성되는 앨범 이름을 설정해요.',
          ),

          const SizedBox(height: PomuSpacing.md),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.photo_album_rounded,
                title: '자동 분류 앨범 이름',
                subtitle: '사진 자동 분류에 사용할 앨범 이름을 변경해요.',
                onTap: () {
                  _openAlbumNameSettings(context);
                },
              ),
            ],
          ),

          const SizedBox(height: PomuSpacing.xl),

          const _SettingsSectionHeader(
            title: '앱 설정',
            subtitle: 'Pomu의 기본 설정을 확인해요.',
          ),

          const SizedBox(height: PomuSpacing.md),

          const _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: '언어',
                subtitle: '현재 아이폰의 언어 설정을 사용해요.',
                trailingText: '한국어',
              ),
            ],
          ),

          const SizedBox(height: PomuSpacing.xl),

          const _SettingsSectionHeader(
            title: '앱 정보',
            subtitle: 'Pomu에 대한 정보를 확인해요.',
          ),

          const SizedBox(height: PomuSpacing.md),

          const _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: '개인정보 처리방침',
                subtitle: '개인정보 처리 내용을 확인해요.',
                enabled: false,
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: '이용약관',
                subtitle: '서비스 이용약관을 확인해요.',
                enabled: false,
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                title: '문의하기',
                subtitle: '앱 이용 중 궁금한 점을 문의해요.',
                enabled: false,
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: '앱 버전',
                subtitle: 'Pomu',
                trailingText: '1.0.0',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PomuColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: PomuColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? trailingText;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailingText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(PomuSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled
                      ? PomuColors.primaryLight
                      : PomuColors.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: enabled
                      ? PomuColors.primary
                      : PomuColors.textSecondary,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: enabled
                            ? PomuColors.textPrimary
                            : PomuColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: PomuColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: PomuSpacing.sm),

              if (trailingText != null)
                Text(
                  trailingText!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PomuColors.textSecondary,
                  ),
                )
              else if (canTap)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: PomuColors.textSecondary,
                )
              else if (!enabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PomuColors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '준비 중',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 76),
      child: Divider(height: 1, thickness: 1, color: PomuColors.divider),
    );
  }
}
