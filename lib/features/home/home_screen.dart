import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../../l10n/app_localizations.dart';
import '../../services/duplicate_summary_service.dart';
import '../duplicates/duplicate_candidates_screen.dart';
import '../scan/scan_progress_screen.dart';
import '../settings/settings_screen.dart';
import '../travel/create_travel_album_screen.dart';
import '../screenshots/screenshot_cleanup_screen.dart';
import '../videos/large_video_cleanup_screen.dart';

extension _HomeL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

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

  Future<void> _openScreenshotCleanup(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScreenshotCleanupScreen()));
  }

  Future<void> _openLargeVideoCleanup(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LargeVideoCleanupScreen()));
  }

  Future<void> _openCreateAlbum(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateTravelAlbumScreen()));
  }

  Future<void> _openAutoClassification(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScanProgressScreen()));
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

    if (!mounted) return;

    await _loadSummary();
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

              Text(
                context.l10n.homeHeroTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                  height: 1.16,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: PomuSpacing.md),

              Text(
                context.l10n.homeHeroSubtitle,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: PomuColors.textSecondary,
                ),
              ),

              const SizedBox(height: 14),

              _MainCleanupCard(
                isLoading: _isLoadingSummary,
                summary: _summary,
                onTap: () => _openDuplicateCleanup(context),
              ),

              const SizedBox(height: PomuSpacing.xxl),

              _SectionTitle(
                title: context.l10n.homeCleanupSectionTitle,
                subtitle: context.l10n.homeCleanupSectionSubtitle,
              ),

              const SizedBox(height: PomuSpacing.md),

              _FeatureCard(
                icon: Icons.screenshot_rounded,
                title: context.l10n.homeScreenshotCleanupTitle,
                description: context.l10n.homeScreenshotCleanupDescription,
                statusText: context.l10n.available,
                isAvailable: true,
                onTap: () => _openScreenshotCleanup(context),
              ),

              const SizedBox(height: PomuSpacing.sm),

              _FeatureCard(
                icon: Icons.video_library_outlined,
                title: context.l10n.homeLargeVideoCleanupTitle,
                description: context.l10n.homeLargeVideoCleanupDescription,
                statusText: context.l10n.available,
                isAvailable: true,
                onTap: () => _openLargeVideoCleanup(context),
              ),

              const SizedBox(height: PomuSpacing.xxl),

              _SectionTitle(
                title: context.l10n.homeAlbumSectionTitle,
                subtitle: context.l10n.homeAlbumSectionSubtitle,
              ),

              const SizedBox(height: PomuSpacing.md),

              _FeatureCard(
                icon: Icons.date_range_rounded,
                title: context.l10n.homeDateTimeAlbumTitle,
                description: context.l10n.homeDateTimeAlbumDescription,
                statusText: context.l10n.available,
                isAvailable: true,
                onTap: () => _openCreateAlbum(context),
              ),

              const SizedBox(height: PomuSpacing.sm),

              _FeatureCard(
                icon: Icons.auto_awesome_rounded,
                title: context.l10n.homeAutoClassificationTitle,
                description: context.l10n.homeAutoClassificationDescription,
                statusText: context.l10n.beta,
                isAvailable: true,
                onTap: () => _openAutoClassification(context),
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
          tooltip: context.l10n.settings,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: PomuColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
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

class _MainCleanupCard extends StatelessWidget {
  final bool isLoading;
  final DuplicateSummary summary;
  final VoidCallback onTap;

  const _MainCleanupCard({
    required this.isLoading,
    required this.summary,
    required this.onTap,
  });

  bool get _hasCandidates =>
      summary.hasScanned && summary.deleteCandidateCount > 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
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
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.content_copy_rounded,
                      size: 24,
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
                    child: Text(
                      summary.hasScanned
                          ? context.l10n.analysisComplete
                          : context.l10n.availableNow,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                context.l10n.duplicateCleanupTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _buildDescription(context),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),

              const SizedBox(height: 16),

              if (isLoading)
                const _DashboardLoading()
              else if (!summary.hasScanned)
                const _BeforeScanDashboard()
              else if (!_hasCandidates)
                const _CleanDashboard()
              else
                _CandidateDashboard(
                  groupCount: summary.groupCount,
                  deleteCandidateCount: summary.deleteCandidateCount,
                ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: PomuSpacing.md,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _buildButtonText(context),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PomuColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
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

  String _buildDescription(BuildContext context) {
    if (isLoading) {
      return context.l10n.homeDuplicateLoading;
    }

    if (!summary.hasScanned) {
      return context.l10n.homeDuplicateBeforeScanDescription;
    }

    if (!_hasCandidates) {
      return context.l10n.homeDuplicateCleanDescription;
    }

    return context.l10n.homeDuplicateHasCandidatesDescription;
  }

  String _buildButtonText(BuildContext context) {
    if (!summary.hasScanned) {
      return context.l10n.homeFindDuplicates;
    }

    if (!_hasCandidates) {
      return context.l10n.duplicateScanAgain;
    }

    return context.l10n.homeCleanDuplicates;
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _BeforeScanDashboard extends StatelessWidget {
  const _BeforeScanDashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PomuSpacing.lg,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_rounded, size: 34, color: Colors.white),
          SizedBox(height: PomuSpacing.sm),
          Text(
            context.l10n.homeStartFirstScan,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            context.l10n.homeFirstScanDescription,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _CleanDashboard extends StatelessWidget {
  const _CleanDashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PomuSpacing.lg,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, size: 38, color: Colors.white),
          SizedBox(height: PomuSpacing.sm),
          Text(
            context.l10n.homeNoDuplicatesTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            context.l10n.homeNoDuplicatesDescription,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _CandidateDashboard extends StatelessWidget {
  final int groupCount;
  final int deleteCandidateCount;

  const _CandidateDashboard({
    required this.groupCount,
    required this.deleteCandidateCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PomuSpacing.lg,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homeGroupCount(groupCount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.homeDeleteCandidateCount(deleteCandidateCount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.homeReclaimableBeforeDelete,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusText;
  final VoidCallback onTap;
  final bool isAvailable;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusText,
    required this.onTap,
    required this.isAvailable,
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
                            color: isAvailable
                                ? PomuColors.primaryLight
                                : PomuColors.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAvailable
                                  ? PomuColors.primary
                                  : PomuColors.textSecondary,
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
