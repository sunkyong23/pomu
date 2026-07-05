import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import 'album_name_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openAlbumNameSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AlbumNameSettingsScreen()));
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
