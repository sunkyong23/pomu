import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../../l10n/app_localizations.dart';
import '../../models/photo_category.dart';
import '../../services/scan_service.dart';

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
  final Stopwatch _analysisStopwatch = Stopwatch();

  ScanStage _stage = ScanStage.loadingPhotos;
  ScanResult? _result;

  int _completed = 0;
  int _total = 0;

  Object? _error;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  @override
  void dispose() {
    _analysisStopwatch.stop();
    super.dispose();
  }

  Future<void> _startProgress() async {
    _analysisStopwatch
      ..stop()
      ..reset();

    setState(() {
      _stage = ScanStage.loadingPhotos;
      _result = null;
      _completed = 0;
      _total = 0;
      _error = null;
    });

    try {
      final result = await _scanService.startOrganizing(
        onProgress: _handleProgress,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _stage = ScanStage.complete;
        _completed = result.totalCount;
        _total = result.totalCount;
      });
    } catch (error, stackTrace) {
      debugPrint('❌ 사진 자동 분류 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _analysisStopwatch.stop();

      setState(() {
        _error = error;
      });
    }
  }

  void _handleProgress(ScanProgress progress) {
    if (!mounted) return;

    if (progress.stage == ScanStage.analyzingPhotos &&
        !_analysisStopwatch.isRunning) {
      _analysisStopwatch.start();
    }

    if (progress.stage != ScanStage.analyzingPhotos &&
        _analysisStopwatch.isRunning) {
      _analysisStopwatch.stop();
    }

    setState(() {
      _stage = progress.stage;
      _completed = progress.completed;
      _total = progress.total;
    });
  }

  Duration? get _estimatedRemaining {
    if (_stage != ScanStage.analyzingPhotos ||
        _completed < 3 ||
        _total <= 0 ||
        !_analysisStopwatch.isRunning) {
      return null;
    }

    final remaining = (_total - _completed).clamp(0, _total);

    if (remaining == 0) {
      return Duration.zero;
    }

    final elapsedMilliseconds = _analysisStopwatch.elapsedMilliseconds;

    if (elapsedMilliseconds <= 0) {
      return null;
    }

    final averageMilliseconds = elapsedMilliseconds / _completed;

    final estimatedMilliseconds = (averageMilliseconds * remaining).round();

    return Duration(milliseconds: estimatedMilliseconds);
  }

  int get _remainingCount {
    final value = _total - _completed;
    return value < 0 ? 0 : value;
  }

  double? get _progressFraction {
    if (_total <= 0) return null;
    return (_completed / _total).clamp(0.0, 1.0);
  }

  int get _currentStep {
    switch (_stage) {
      case ScanStage.loadingPhotos:
        return 0;
      case ScanStage.analyzingPhotos:
        return 1;
      case ScanStage.creatingAlbums:
        return 2;
      case ScanStage.complete:
        return 3;
    }
  }

  String _stageMessage(BuildContext context) {
    switch (_stage) {
      case ScanStage.loadingPhotos:
        return context.l10n.scanCheckingNewPhotos;
      case ScanStage.analyzingPhotos:
        return context.l10n.scanAnalyzingPhotos;
      case ScanStage.creatingAlbums:
        return context.l10n.scanPreparingAlbums;
      case ScanStage.complete:
        return context.l10n.scanCompleteTitle;
    }
  }

  String _etaText(BuildContext context) {
    final duration = _estimatedRemaining;

    if (duration == null) {
      return context.l10n.scanCalculatingRemainingTime;
    }

    if (duration <= Duration.zero) {
      return context.l10n.scanAlmostDone;
    }

    final totalMinutes = duration.inMinutes;

    if (totalMinutes < 1) {
      return context.l10n.scanLessThanOneMinuteRemaining;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return context.l10n.scanEstimatedHoursMinutesRemaining(hours, minutes);
    }

    if (hours > 0) {
      return context.l10n.scanEstimatedHoursRemaining(hours);
    }

    return context.l10n.scanEstimatedMinutesRemaining(minutes);
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _stage == ScanStage.complete && _result != null;

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
                    : _error != null
                    ? context.l10n.scanOrganizeFailedTitle
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
              if (!isComplete && _error == null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _stageMessage(context),
                    key: ValueKey(_stage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: PomuSpacing.xl),
              if (_error != null)
                _ErrorView(
                  message: context.l10n.scanOrganizeFailedDescription,
                  retryText: context.l10n.scanRetry,
                  onRetry: _startProgress,
                )
              else if (isComplete)
                _CompleteSummary(result: _result!)
              else
                Column(
                  children: [
                    _StepIndicator(currentStep: _currentStep),
                    const SizedBox(height: PomuSpacing.md),
                    _LiveProgressCard(
                      stage: _stage,
                      completed: _completed,
                      total: _total,
                      progress: _progressFraction,
                      remainingText: context.l10n.scanRemainingPhotos(
                        _remainingCount,
                      ),
                      etaText: _etaText(context),
                    ),
                  ],
                ),
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

class _LiveProgressCard extends StatelessWidget {
  final ScanStage stage;
  final int completed;
  final int total;
  final double? progress;
  final String remainingText;
  final String etaText;

  const _LiveProgressCard({
    required this.stage,
    required this.completed,
    required this.total,
    required this.progress,
    required this.remainingText,
    required this.etaText,
  });

  @override
  Widget build(BuildContext context) {
    final isAnalyzing = stage == ScanStage.analyzingPhotos;
    final hasTotal = total > 0;
    final percent = ((progress ?? 0) * 100).round().clamp(0, 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isAnalyzing && hasTotal
                      ? context.l10n.scanProcessedCount(completed, total)
                      : _stageLabel(context, stage),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                  ),
                ),
              ),
              if (isAnalyzing && hasTotal)
                Text(
                  context.l10n.scanProgressPercent(percent),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: PomuSpacing.md),
          LinearProgressIndicator(
            value: isAnalyzing ? progress : null,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
            color: PomuColors.primary,
            backgroundColor: PomuColors.primaryLight,
          ),
          if (isAnalyzing && hasTotal) ...[
            const SizedBox(height: PomuSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    remainingText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  etaText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PomuColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _stageLabel(BuildContext context, ScanStage stage) {
    switch (stage) {
      case ScanStage.loadingPhotos:
        return context.l10n.scanCheckingNewPhotos;
      case ScanStage.analyzingPhotos:
        return context.l10n.scanAnalyzingPhotos;
      case ScanStage.creatingAlbums:
        return context.l10n.scanPreparingAlbums;
      case ScanStage.complete:
        return context.l10n.scanCompleteTitle;
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String retryText;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.retryText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: PomuColors.primary,
            size: 42,
          ),
          const SizedBox(height: PomuSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: PomuColors.textSecondary,
            ),
          ),
          const SizedBox(height: PomuSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onRetry, child: Text(retryText)),
          ),
        ],
      ),
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
