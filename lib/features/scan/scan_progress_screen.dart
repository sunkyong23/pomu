import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../../l10n/app_localizations.dart';
import '../../models/photo_category.dart';
import '../../services/scan_service.dart';
import '../home/home_screen.dart';

extension _ScanProgressL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String _localizedCategoryName(BuildContext context, PhotoCategory category) {
  switch (category) {
    case PhotoCategory.pets:
      return context.l10n.categoryPets;
    case PhotoCategory.people:
      return context.l10n.categoryPeople;
    case PhotoCategory.food:
      return context.l10n.categoryFood;
    case PhotoCategory.landscape:
      return context.l10n.categoryLandscape;
    case PhotoCategory.documents:
      return context.l10n.categoryDocuments;
    case PhotoCategory.screenshots:
      return context.l10n.categoryScreenshots;
    case PhotoCategory.receipts:
      return context.l10n.categoryReceipts;
    case PhotoCategory.other:
      return context.l10n.categoryOther;
  }
}

class ScanProgressScreen extends StatefulWidget {
  const ScanProgressScreen({super.key});

  @override
  State<ScanProgressScreen> createState() => _ScanProgressScreenState();
}

class _ScanProgressScreenState extends State<ScanProgressScreen> {
  final ScanService _scanService = ScanService();

  int _step = 0;
  ScanResult? _result;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  Future<void> _startProgress() async {
    setState(() => _step = 0);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _step = 1);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _step = 2);

    final result = await _scanService.startOrganizing();

    if (!mounted) return;
    setState(() {
      _result = result;
      _step = 3;
    });
  }

  void _goHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _step == 3 && _result != null;
    final messages = [
      context.l10n.scanCheckingNewPhotos,
      context.l10n.scanAnalyzingPhotos,
      context.l10n.scanPreparingAlbums,
      context.l10n.scanCompleteTitle,
    ];

    return Scaffold(
      backgroundColor: PomuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Semantics(
                label: context.l10n.appName,
                image: true,
                child: PomuLogo(size: isComplete ? 72 : 96),
              ),
              const SizedBox(height: PomuSpacing.xl),
              Text(
                isComplete
                    ? context.l10n.scanCompleteTitle
                    : context.l10n.scanWorkingTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: PomuSpacing.md),
              if (!isComplete)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    messages[_step],
                    key: ValueKey(messages[_step]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: PomuSpacing.xl),
              if (isComplete)
                _CompleteSummary(result: _result!)
              else
                _StepIndicator(currentStep: _step),
              const Spacer(),
              if (isComplete)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Semantics(
                    button: true,
                    label: context.l10n.scanBackHome,
                    child: ElevatedButton(
                      onPressed: _goHome,
                      child: Text(
                        context.l10n.scanBackHome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isComplete) const SizedBox(height: PomuSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final items = [
      context.l10n.scanStepPhotoCheck,
      context.l10n.scanStepAiAnalysis,
      context.l10n.scanStepAlbumCreation,
    ];

    return Column(
      children: List.generate(items.length, (index) {
        final isDone = currentStep > index;
        final isCurrent = currentStep == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: PomuSpacing.md),
          child: Row(
            children: [
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : isCurrent
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isDone || isCurrent
                    ? PomuColors.primary
                    : PomuColors.divider,
              ),
              const SizedBox(width: PomuSpacing.sm),
              Text(
                items[index],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent || isDone
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isCurrent || isDone
                      ? PomuColors.textPrimary
                      : PomuColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CompleteSummary extends StatelessWidget {
  final ScanResult result;

  const _CompleteSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    final entries = result.categorizedPhotos.entries.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PomuColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: PomuColors.mint,
            size: 42,
          ),
          const SizedBox(height: PomuSpacing.md),
          Text(
            context.l10n.scanTotalOrganized(result.totalCount),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: PomuSpacing.xs),
          Text(
            context.l10n.scanAlbumCount(result.albumCount),
            style: const TextStyle(
              fontSize: 15,
              color: PomuColors.textSecondary,
            ),
          ),
          const SizedBox(height: PomuSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: PomuSpacing.md),
          ...entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: PomuSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _localizedCategoryName(context, entry.key),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PomuColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.photoCount(entry.value.length),
                    style: const TextStyle(
                      fontSize: 15,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
