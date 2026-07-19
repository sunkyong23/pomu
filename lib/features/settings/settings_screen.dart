import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../services/duplicate_history_service.dart';
import '../../services/duplicate_result_cache_service.dart';
import '../../services/duplicate_summary_service.dart';
import 'album_name_settings_screen.dart';

extension _SettingsL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String _currentLanguageName(BuildContext context) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'en':
      return 'English';
    case 'ja':
      return '日本語';
    case 'zh':
      return '简体中文';
    case 'ko':
    default:
      return '한국어';
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openAlbumNameSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AlbumNameSettingsScreen()));
  }

  Future<void> _openWebPage(BuildContext context, String page) async {
    final languageCode = Localizations.localeOf(context).languageCode;

    final lang = switch (languageCode) {
      'ko' => 'ko',
      'ja' => 'ja',
      'zh' => 'zh',
      _ => 'en',
    };

    final uri = Uri.https('sunkyong23.github.io', '/pomu/$page', {
      'lang': lang,
    });

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showClearDuplicateResultDialog(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: PomuColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: PomuColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restart_alt_rounded,
                    size: 30,
                    color: PomuColors.primary,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  dialogContext.l10n.settingsResetDialogTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: PomuColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  dialogContext.l10n.settingsResetDialogDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: PomuColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PomuColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: PomuColors.divider),
                  ),
                  child: Column(
                    children: [
                      _ResetNoticeRow(
                        icon: Icons.refresh_rounded,
                        text: dialogContext
                            .l10n
                            .settingsResetNoticeResolvedGroups,
                      ),
                      SizedBox(height: 12),
                      _ResetNoticeRow(
                        icon: Icons.photo_outlined,
                        text: dialogContext.l10n.settingsResetNoticePhotosSafe,
                      ),
                      SizedBox(height: 12),
                      _ResetNoticeRow(
                        icon: Icons.lock_outline_rounded,
                        text:
                            dialogContext.l10n.settingsResetNoticePurchaseKept,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PomuColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      dialogContext.l10n.settingsResetAction,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: PomuColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      dialogContext.l10n.cancel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            content: Text(context.l10n.settingsResetSuccess),
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
            content: Text(context.l10n.settingsResetFailure),
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
        title: Text(
          context.l10n.settingsTitle,
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
          _SettingsSectionHeader(
            title: context.l10n.settingsPhotoCleanupSectionTitle,
            subtitle: context.l10n.settingsPhotoCleanupSectionSubtitle,
          ),

          const SizedBox(height: PomuSpacing.md),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.restart_alt_rounded,
                title: context.l10n.settingsResetDuplicateTitle,
                subtitle: context.l10n.settingsResetDuplicateSubtitle,
                onTap: () {
                  _showClearDuplicateResultDialog(context);
                },
              ),
            ],
          ),

          const SizedBox(height: PomuSpacing.xl),

          _SettingsSectionHeader(
            title: context.l10n.settingsAlbumSectionTitle,
            subtitle: context.l10n.settingsAlbumSectionSubtitle,
          ),

          const SizedBox(height: PomuSpacing.md),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.photo_album_rounded,
                title: context.l10n.settingsAutoAlbumNameTitle,
                subtitle: context.l10n.settingsAutoAlbumNameSubtitle,
                onTap: () {
                  _openAlbumNameSettings(context);
                },
              ),
            ],
          ),

          const SizedBox(height: PomuSpacing.xl),

          _SettingsSectionHeader(
            title: context.l10n.settingsAppSectionTitle,
            subtitle: context.l10n.settingsAppSectionSubtitle,
          ),

          const SizedBox(height: PomuSpacing.md),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: context.l10n.settingsLanguageTitle,
                subtitle: context.l10n.settingsLanguageSubtitle,
                trailingText: _currentLanguageName(context),
              ),
            ],
          ),

          const SizedBox(height: PomuSpacing.xl),

          _SettingsSectionHeader(
            title: context.l10n.settingsInfoSectionTitle,
            subtitle: context.l10n.settingsInfoSectionSubtitle,
          ),

          const SizedBox(height: PomuSpacing.md),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: context.l10n.settingsPrivacyPolicyTitle,
                subtitle: context.l10n.settingsPrivacyPolicySubtitle,
                onTap: () => _openWebPage(context, 'privacy.html'),
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: context.l10n.settingsTermsTitle,
                subtitle: context.l10n.settingsTermsSubtitle,
                onTap: () => _openWebPage(context, 'terms.html'),
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                title: context.l10n.settingsContactTitle,
                subtitle: context.l10n.settingsContactSubtitle,
                onTap: () => _openWebPage(context, 'support.html'),
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: context.l10n.settingsAppVersionTitle,
                subtitle: context.l10n.appName,
                trailingText: '1.0.6',
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
  final String? subtitle;
  final VoidCallback? onTap;
  final String? trailingText;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = onTap != null;

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
                  color: PomuColors.primaryLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 22, color: PomuColors.primary),
              ),

              const SizedBox(width: PomuSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PomuColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: PomuColors.textSecondary,
                        ),
                      ),
                    ],
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

class _ResetNoticeRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ResetNoticeRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: PomuColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: PomuColors.primary),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: PomuColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
