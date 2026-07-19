import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../../l10n/app_localizations.dart';
import 'scan_progress_screen.dart';

extension _AutoClassificationIntroL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class AutoClassificationIntroScreen extends StatelessWidget {
  const AutoClassificationIntroScreen({super.key});

  void _startClassification(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScanProgressScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      appBar: AppBar(
        backgroundColor: PomuColors.background,
        foregroundColor: PomuColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          context.l10n.autoClassificationIntroAppBarTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PomuColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PomuSpacing.lg,
            PomuSpacing.md,
            PomuSpacing.lg,
            PomuSpacing.lg,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: PomuSpacing.sm),
                      _IntroHeroCard(),
                      const SizedBox(height: PomuSpacing.lg),
                      _WarningCard(),
                      const SizedBox(height: PomuSpacing.md),
                      _InfoCard(
                        icon: Icons.lock_outline_rounded,
                        title: context.l10n.autoClassificationPrivacyTitle,
                        description:
                            context.l10n.autoClassificationPrivacyDescription,
                      ),
                      const SizedBox(height: PomuSpacing.sm),
                      _InfoCard(
                        icon: Icons.photo_library_outlined,
                        title: context.l10n.autoClassificationAlbumTitle,
                        description:
                            context.l10n.autoClassificationAlbumDescription,
                      ),
                      const SizedBox(height: PomuSpacing.sm),
                      _InfoCard(
                        icon: Icons.update_rounded,
                        title: context.l10n.autoClassificationNextScanTitle,
                        description:
                            context.l10n.autoClassificationNextScanDescription,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: PomuSpacing.md),
              PomuPrimaryButton(
                text: context.l10n.autoClassificationStartButton,
                icon: Icons.auto_awesome_rounded,
                onPressed: () => _startClassification(context),
              ),
              const SizedBox(height: PomuSpacing.sm),
              Text(
                context.l10n.autoClassificationStartNotice,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: PomuColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: PomuColors.primaryLight,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: PomuColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PomuColors.primary.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(child: PomuLogo(size: 42)),
          ),
          const SizedBox(height: PomuSpacing.lg),
          Text(
            context.l10n.autoClassificationIntroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              height: 1.28,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: PomuSpacing.sm),
          Text(
            context.l10n.autoClassificationIntroDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: PomuColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const warningBackground = Color(0xFFFFF7E8);
    const warningBorder = Color(0xFFFFDFA1);
    const warningIcon = Color(0xFFD98300);
    const warningText = Color(0xFF815315);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: warningBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, size: 24, color: warningIcon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.autoClassificationWarningTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: warningText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.autoClassificationWarningDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: warningText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PomuColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 21, color: PomuColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PomuColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: PomuColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
