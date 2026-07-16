import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../l10n/app_localizations.dart';
import '../../models/duplicate_photo_group.dart';
import '../../services/duplicate_detector_service.dart';
import '../../services/duplicate_history_service.dart';
import '../../services/duplicate_result_cache_service.dart';
import '../../services/duplicate_summary_service.dart';
import '../../services/purchase_access_service.dart';
import '../purchase/duplicate_cleanup_purchase_sheet.dart';

extension _DuplicateCandidatesL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class DuplicateCandidatesScreen extends StatefulWidget {
  const DuplicateCandidatesScreen({super.key});

  @override
  State<DuplicateCandidatesScreen> createState() =>
      _DuplicateCandidatesScreenState();
}

class _DuplicateCandidatesScreenState extends State<DuplicateCandidatesScreen> {
  final DuplicateDetectorService _service = DuplicateDetectorService();
  final DuplicateHistoryService _historyService = DuplicateHistoryService();
  final DuplicateSummaryService _summaryService = DuplicateSummaryService();
  final DuplicateResultCacheService _resultCacheService =
      DuplicateResultCacheService();

  static const int _cachePageSize = 100;

  bool _isLoading = false;
  bool _isSavingResult = false;
  bool _isInitializing = true;
  bool _isLoadingMore = false;

  int _progressCurrent = 0;
  int _progressTotal = 0;
  int _cachedGroupOffset = 0;
  int _totalCachedGroupCount = 0;

  List<DuplicatePhotoGroup> _groups = [];
  DuplicateSummary _savedSummary = const DuplicateSummary.empty();

  final Set<String> _resolvedGroupKeys = {};

  bool get _isBusy => _isLoading || _isSavingResult;
  bool get _hasMoreCachedGroups => _cachedGroupOffset < _totalCachedGroupCount;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  String _buildGroupKeyFromIds(List<String> ids) {
    final sorted = [...ids]..sort();
    return sorted.join('|');
  }

  Future<void> _loadInitialData() async {
    try {
      final resolvedGroups = await _historyService.loadResolvedGroups();
      final summary = await _summaryService.loadSummary();
      final totalCachedGroupCount = await _resultCacheService
          .getSavedGroupCount();

      final cachedGroups = await _resultCacheService.loadGroups(
        offset: 0,
        limit: _cachePageSize,
      );

      final filteredGroups = cachedGroups.where((group) {
        final key = _buildGroupKeyFromIds(
          group.assets.map((asset) => asset.id).toList(),
        );

        return !resolvedGroups.contains(key);
      }).toList();

      if (!mounted) return;

      setState(() {
        _resolvedGroupKeys
          ..clear()
          ..addAll(resolvedGroups);

        _savedSummary = summary;
        _groups = filteredGroups;
        _totalCachedGroupCount = totalCachedGroupCount;
        _cachedGroupOffset = _cachePageSize.clamp(0, totalCachedGroupCount);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.duplicateLoadLastResultError(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadMoreCachedGroups() async {
    if (_isLoadingMore || !_hasMoreCachedGroups || _isBusy || _isInitializing) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextGroups = await _resultCacheService.loadGroups(
        offset: _cachedGroupOffset,
        limit: _cachePageSize,
      );

      final filteredNextGroups = nextGroups.where((group) {
        final key = _buildGroupKeyFromIds(
          group.assets.map((asset) => asset.id).toList(),
        );

        return !_resolvedGroupKeys.contains(key);
      }).toList();

      if (!mounted) return;

      setState(() {
        final existingIds = _groups.map((group) => group.id).toSet();

        _groups.addAll(
          filteredNextGroups.where((group) => !existingIds.contains(group.id)),
        );

        _cachedGroupOffset = (_cachedGroupOffset + _cachePageSize).clamp(
          0,
          _totalCachedGroupCount,
        );

        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.duplicateLoadMoreError(e.toString())),
        ),
      );
    }
  }

  Future<void> _scan() async {
    if (_isBusy || _isInitializing) return;

    setState(() {
      _isLoading = true;
      _isSavingResult = false;
      _progressCurrent = 0;
      _progressTotal = 0;
    });

    try {
      final groups = await _service.findDuplicateCandidates(
        onProgress: (current, total) {
          if (!mounted) return;

          setState(() {
            _progressCurrent = current;
            _progressTotal = total;
          });
        },
      );

      if (!mounted) return;

      final filteredGroups = groups.where((group) {
        final key = _buildGroupKeyFromIds(
          group.assets.map((asset) => asset.id).toList(),
        );

        return !_resolvedGroupKeys.contains(key);
      }).toList();

      // 사진 분석은 끝났지만 캐시와 대시보드 저장은 아직 진행 중이에요.
      setState(() {
        _groups = filteredGroups;
        _isLoading = false;
        _isSavingResult = true;
      });

      await _resultCacheService.saveGroups(filteredGroups);
      await _saveCurrentSummary(filteredGroups);

      final updatedSummary = await _summaryService.loadSummary();

      if (!mounted) return;

      setState(() {
        _savedSummary = updatedSummary;
        _isSavingResult = false;
        _totalCachedGroupCount = filteredGroups.length;
        _cachedGroupOffset = filteredGroups.length;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSavingResult = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.duplicateAnalysisError(e.toString())),
        ),
      );
    }
  }

  Future<void> _resolveGroup(
    DuplicatePhotoGroup resolvedGroup,
    List<String> remainingAssetIds,
    int deletedCount,
    int deletedBytes,
  ) async {
    if (_isSavingResult) return;

    // 해결 기록은 삭제 전 원래 그룹 구성으로 저장해요.
    final originalGroupKey = _buildGroupKeyFromIds(
      resolvedGroup.assets.map((asset) => asset.id).toList(),
    );

    final updatedGroups = _groups
        .where((group) => group.id != resolvedGroup.id)
        .toList();

    setState(() {
      _resolvedGroupKeys.add(originalGroupKey);
      _groups = updatedGroups;
      _isSavingResult = true;
    });

    try {
      debugPrint('💾 1. 해결 그룹 기록 시작');
      await _historyService.saveResolvedGroup(originalGroupKey);
      debugPrint('✅ 1. 해결 그룹 기록 완료');

      debugPrint('💾 2. 캐시 그룹 제거 시작: ${resolvedGroup.id}');
      await _resultCacheService.removeGroupById(resolvedGroup.id);
      debugPrint('✅ 2. 캐시 그룹 제거 완료');

      final nextGroupCount = math.max(0, _savedSummary.groupCount - 1);

      final nextDeleteCandidateCount = math.max(
        0,
        _savedSummary.deleteCandidateCount - deletedCount,
      );

      final nextReclaimableBytes = math.max(
        0,
        _savedSummary.reclaimableBytes - deletedBytes,
      );

      debugPrint(
        '💾 3. 요약 저장 시작: '
        'groupCount=$nextGroupCount, '
        'deleteCandidateCount=$nextDeleteCandidateCount, '
        'reclaimableBytes=$nextReclaimableBytes',
      );

      await _summaryService.saveSummary(
        groupCount: nextGroupCount,
        deleteCandidateCount: nextDeleteCandidateCount,
        reclaimableBytes: nextReclaimableBytes,
      );

      debugPrint('✅ 3. 요약 저장 완료');

      final updatedSummary = await _summaryService.loadSummary();

      if (!mounted) return;

      setState(() {
        _savedSummary = updatedSummary;
        _isSavingResult = false;

        _totalCachedGroupCount = math.max(0, _totalCachedGroupCount - 1);

        _cachedGroupOffset = math.min(
          _cachedGroupOffset,
          _totalCachedGroupCount,
        );
      });
    } catch (error, stackTrace) {
      debugPrint('❌ 삭제 결과 저장 실패: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isSavingResult = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.duplicateSaveDeleteResultError(error.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _saveCurrentSummary(List<DuplicatePhotoGroup> groups) async {
    final deleteCandidateCount = groups.fold<int>(
      0,
      (sum, group) => sum + group.deleteCandidateCount,
    );

    await _summaryService.saveSummary(
      groupCount: groups.length,
      deleteCandidateCount: deleteCandidateCount,
      reclaimableBytes: 0,
    );
  }

  void _handleBlockedBack() {
    final message = _isSavingResult
        ? context.l10n.duplicateSavingWait
        : context.l10n.duplicateAnalyzingWait;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context);

    debugPrint('🌍 Flutter locale: $locale');
    debugPrint('🌍 Localized title: ${l10n.duplicateCleanupTitle}');
    debugPrint('🌍 Flutter locale: ${Localizations.localeOf(context)}');
    return PopScope(
      canPop: !_isBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_isBusy) return;

        _handleBlockedBack();
      },
      child: Scaffold(
        backgroundColor: PomuColors.background,
        appBar: AppBar(
          backgroundColor: PomuColors.background,
          elevation: 0,
          title: Text(
            context.l10n.duplicateCleanupTitle,
            style: TextStyle(
              color: PomuColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          children: [
            Text(
              context.l10n.duplicateIntroTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
                height: 1.15,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: PomuSpacing.md),
            Text(
              context.l10n.duplicateIntroDescription,
              style: TextStyle(
                fontSize: 15,
                color: PomuColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: PomuSpacing.xl),

            PomuPrimaryButton(
              text: _isSavingResult
                  ? context.l10n.duplicateSavingShort
                  : _isLoading
                  ? context.l10n.duplicateAnalyzingShort
                  : _savedSummary.hasScanned
                  ? context.l10n.duplicateScanAgain
                  : context.l10n.duplicateFindCandidates,
              icon: _isSavingResult
                  ? Icons.save_rounded
                  : Icons.cleaning_services_rounded,
              onPressed: _isBusy || _isInitializing ? null : _scan,
            ),

            const SizedBox(height: PomuSpacing.xl),

            if (_isInitializing) ...[
              const _RestoreLoadingCard(),
              const SizedBox(height: PomuSpacing.lg),
            ],

            if (_isLoading || _isSavingResult) ...[
              _ProgressCard(
                current: _progressCurrent,
                total: _progressTotal,
                isSavingResult: _isSavingResult,
              ),
              const SizedBox(height: PomuSpacing.lg),
            ],

            if (_groups.isNotEmpty) ...[
              _SummaryCard(
                visibleGroupCount: _groups.length,
                totalGroupCount: _savedSummary.groupCount,
                deleteCandidateCount: _savedSummary.deleteCandidateCount,
              ),
              const SizedBox(height: PomuSpacing.lg),

              ..._groups.map(
                (group) => _DuplicateGroupCard(
                  key: ValueKey(group.id),
                  group: group,
                  isBusy: _isSavingResult,
                  onDeleted: (remainingAssetIds, deletedCount, deletedBytes) {
                    return _resolveGroup(
                      group,
                      remainingAssetIds,
                      deletedCount,
                      deletedBytes,
                    );
                  },
                ),
              ),

              if (_hasMoreCachedGroups) ...[
                const SizedBox(height: PomuSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingMore ? null : _loadMoreCachedGroups,
                    icon: _isLoadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: PomuColors.primary,
                            ),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: Text(
                      _isLoadingMore
                          ? context.l10n.loading
                          : context.l10n.duplicateLoadMore,
                    ),
                  ),
                ),
                const SizedBox(height: PomuSpacing.md),
              ],
            ],

            if (!_isBusy && !_isInitializing && _groups.isEmpty)
              _EmptyCard(hasScanned: _savedSummary.hasScanned),
          ],
        ),
      ),
    );
  }
}

class _RestoreLoadingCard extends StatelessWidget {
  const _RestoreLoadingCard();

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
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: PomuColors.primary,
            ),
          ),
          SizedBox(width: PomuSpacing.md),
          Expanded(
            child: Text(
              context.l10n.duplicateRestoringLastResult,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PomuColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int current;
  final int total;
  final bool isSavingResult;

  const _ProgressCard({
    required this.current,
    required this.total,
    required this.isSavingResult,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = total > 0;
    final progress = hasProgress ? current / total : null;
    final percent = hasProgress ? ((progress ?? 0) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSavingResult
                ? context.l10n.duplicateSavingResult
                : context.l10n.duplicateReanalyzing,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          LinearProgressIndicator(
            value: isSavingResult ? null : progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            color: PomuColors.primary,
            backgroundColor: PomuColors.primaryLight,
          ),
          const SizedBox(height: PomuSpacing.md),
          Text(
            isSavingResult
                ? context.l10n.duplicateSavingSafely
                : hasProgress
                ? context.l10n.duplicateProgress(percent, current, total)
                : context.l10n.duplicateFindingCandidates,
            style: const TextStyle(
              fontSize: 14,
              color: PomuColors.textSecondary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            isSavingResult
                ? context.l10n.duplicateContinueSoon
                : context.l10n.duplicateMayTakeTime,
            style: const TextStyle(
              fontSize: 13,
              color: PomuColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int visibleGroupCount;
  final int totalGroupCount;
  final int deleteCandidateCount;

  const _SummaryCard({
    required this.visibleGroupCount,
    required this.totalGroupCount,
    required this.deleteCandidateCount,
  });

  @override
  Widget build(BuildContext context) {
    final isPartiallyLoaded = visibleGroupCount < totalGroupCount;

    return Container(
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: PomuColors.primary,
            size: 30,
          ),
          const SizedBox(width: PomuSpacing.md),
          Expanded(
            child: Text(
              isPartiallyLoaded
                  ? context.l10n.duplicateSummaryPartial(
                      totalGroupCount,
                      visibleGroupCount,
                      deleteCandidateCount,
                    )
                  : context.l10n.duplicateSummaryFull(
                      totalGroupCount,
                      deleteCandidateCount,
                    ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateGroupCard extends StatefulWidget {
  final DuplicatePhotoGroup group;
  final bool isBusy;
  final Future<void> Function(
    List<String> remainingAssetIds,
    int deletedCount,
    int deletedBytes,
  )
  onDeleted;

  const _DuplicateGroupCard({
    super.key,
    required this.group,
    required this.isBusy,
    required this.onDeleted,
  });

  @override
  State<_DuplicateGroupCard> createState() => _DuplicateGroupCardState();
}

class _DuplicateGroupCardState extends State<_DuplicateGroupCard> {
  late Set<String> _keeperAssetIds;

  @override
  void initState() {
    super.initState();
    _resetKeeperSelection();
  }

  @override
  void didUpdateWidget(covariant _DuplicateGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.group.id != widget.group.id) {
      _resetKeeperSelection();
    }
  }

  void _resetKeeperSelection() {
    _keeperAssetIds = {widget.group.keeper.id};
  }

  void _toggleKeeper(AssetEntity asset) {
    if (widget.isBusy) return;

    setState(() {
      if (_keeperAssetIds.contains(asset.id)) {
        if (_keeperAssetIds.length == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.duplicateKeeperMinimum)),
          );
          return;
        }

        _keeperAssetIds.remove(asset.id);
      } else {
        _keeperAssetIds.add(asset.id);
      }
    });
  }

  void _showPhotoPreview(AssetEntity asset) {
    if (widget.isBusy) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) {
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: FutureBuilder(
                      future: asset.thumbnailDataWithSize(
                        const ThumbnailSize(1600, 1600),
                        quality: 95,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () {},
                          child: InteractiveViewer(
                            minScale: 1,
                            maxScale: 5,
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteRequest(List<AssetEntity> deleteAssets) async {
    if (deleteAssets.isEmpty || widget.isBusy) return;

    final accessService = PurchaseAccessService.instance;

    if (!accessService.canDeleteDuplicateGroup) {
      final purchased = await showDuplicateCleanupPurchaseSheet(context);

      if (!mounted || !purchased) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.purchaseCompletedContinueDelete)),
      );
    }

    if (!mounted) return;

    await _showDeletePreviewSheet(deleteAssets);
  }

  Future<void> _deleteAssets(List<AssetEntity> deleteAssets) async {
    if (widget.isBusy) return;

    final ids = deleteAssets.map((asset) => asset.id).toList();

    if (ids.isEmpty) return;

    final accessService = PurchaseAccessService.instance;

    if (!accessService.canDeleteDuplicateGroup) {
      final purchased = await showDuplicateCleanupPurchaseSheet(context);

      if (!mounted || !purchased) return;
    }

    final wasFreeDelete = accessService.isNextDeleteFree;
    final deletedBytes = await _calculateTotalFileSize(deleteAssets);

    final deletedIds = await PhotoManager.editor.deleteWithIds(ids);

    if (!mounted) return;

    if (deletedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.deleteCanceledOrFailed)),
      );
      return;
    }

    if (wasFreeDelete) {
      await accessService.markFreeDeleteUsed();
    }

    if (!mounted) return;

    final deletedIdSet = deletedIds.toSet();

    final remainingAssetIds = widget.group.assets
        .where((asset) => !deletedIdSet.contains(asset.id))
        .map((asset) => asset.id)
        .toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFreeDelete
              ? context.l10n.freeDeleteCompleted(deletedIds.length)
              : context.l10n.deleteMovedToRecentlyDeleted(deletedIds.length),
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _resetKeeperSelection();
    });

    await widget.onDeleted(remainingAssetIds, deletedIds.length, deletedBytes);
  }

  Future<void> _showDeletePreviewSheet(List<AssetEntity> deleteAssets) async {
    final totalBytes = await _calculateTotalFileSize(deleteAssets);

    if (!mounted) return;

    final readableSize = _formatBytes(context, totalBytes);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          decoration: const BoxDecoration(
            color: PomuColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetContext.l10n.deletePreparation,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sheetContext.l10n.deleteCandidatesReview(deleteAssets.length),
                  style: const TextStyle(
                    fontSize: 14,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(PomuSpacing.md),
                  decoration: BoxDecoration(
                    color: PomuColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    sheetContext.l10n.estimatedSpace(readableSize),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: PomuColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: PomuSpacing.md),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: deleteAssets.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(width: 8);
                    },
                    itemBuilder: (context, index) {
                      final asset = deleteAssets[index];

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: FutureBuilder(
                          future: asset.thumbnailDataWithSize(
                            const ThumbnailSize(180, 180),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                              return Container(
                                width: 88,
                                height: 88,
                                color: PomuColors.primaryLight,
                              );
                            }

                            return Image.memory(
                              snapshot.data!,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: PomuSpacing.lg),
                Text(
                  sheetContext.l10n.deletedPhotosMoveToRecentlyDeleted,
                  style: TextStyle(
                    fontSize: 13,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(sheetContext.l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: PomuSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _deleteAssets(deleteAssets);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          sheetContext.l10n.deleteCount(deleteAssets.length),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int> _calculateTotalFileSize(List<AssetEntity> assets) async {
    final sizes = await Future.wait<int>(
      assets.map(_tryGetAssetFileSizeForGroup),
    );

    return sizes.fold<int>(0, (sum, size) => sum + size);
  }

  Future<int> _tryGetAssetFileSizeForGroup(AssetEntity asset) async {
    try {
      // iCloud 사진은 불러오는 데 시간이 걸릴 수 있으므로
      // 기존 1초보다 넉넉하게 기다려요.
      final file = await asset.file.timeout(const Duration(seconds: 8));

      if (file == null) {
        debugPrint('⚠️ 파일을 가져오지 못함: ${asset.id}');
        return 0;
      }

      final size = await file.length().timeout(const Duration(seconds: 3));

      debugPrint('📦 파일 크기: ${asset.id} / $size bytes');

      return size;
    } on TimeoutException {
      debugPrint('⏱️ 파일 크기 확인 시간 초과: ${asset.id}');
      return 0;
    } catch (error) {
      debugPrint('❌ 파일 크기 확인 실패: ${asset.id} / $error');
      return 0;
    }
  }

  String _formatBytes(BuildContext context, int bytes) {
    if (bytes <= 0) return context.l10n.unableToCheckSize;

    final mb = bytes / (1024 * 1024);

    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)}MB';
    }

    final gb = mb / 1024;

    return '${gb.toStringAsFixed(2)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final keeperCount = _keeperAssetIds.length;

    final selectedCount = (widget.group.assets.length - keeperCount).clamp(
      0,
      9999,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: PomuSpacing.md),
      padding: const EdgeInsets.all(PomuSpacing.md),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.duplicateCandidateCount(widget.group.count),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.keeperAndDeleteCount(keeperCount, selectedCount),
            style: const TextStyle(
              fontSize: 13,
              color: PomuColors.textSecondary,
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.group.assets.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final asset = widget.group.assets[index];
                final isKeeper = _keeperAssetIds.contains(asset.id);

                return GestureDetector(
                  onTap: widget.isBusy ? null : () => _toggleKeeper(asset),
                  onLongPress: widget.isBusy
                      ? null
                      : () => _showPhotoPreview(asset),
                  child: _SelectableThumbnailTile(
                    asset: asset,
                    isKeeper: isKeeper,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          OutlinedButton.icon(
            onPressed: selectedCount == 0 || widget.isBusy
                ? null
                : () {
                    final deleteAssets = widget.group.assets
                        .where((asset) => !_keeperAssetIds.contains(asset.id))
                        .toList();

                    _handleDeleteRequest(deleteAssets);
                  },
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(
              selectedCount == 0
                  ? context.l10n.noPhotosToDelete
                  : widget.isBusy
                  ? context.l10n.duplicateSavingShort
                  : context.l10n.deletePreparationCount(selectedCount),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableThumbnailTile extends StatelessWidget {
  final AssetEntity asset;
  final bool isKeeper;

  const _SelectableThumbnailTile({required this.asset, required this.isKeeper});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 96,
      height: 96,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FutureBuilder(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize(220, 220),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Container(
                    width: 96,
                    height: 96,
                    color: PomuColors.primaryLight,
                  );
                }

                return Image.memory(
                  snapshot.data!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isKeeper
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isKeeper ? PomuColors.primary : Colors.transparent,
                width: isKeeper ? 3 : 0,
              ),
            ),
          ),
          Positioned(
            left: 7,
            top: 7,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isKeeper
                    ? PomuColors.primary
                    : Colors.black.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isKeeper ? context.l10n.keep : context.l10n.deleteCandidate,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final bool hasScanned;

  const _EmptyCard({required this.hasScanned});

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
          Icon(
            hasScanned
                ? Icons.check_circle_outline_rounded
                : Icons.search_rounded,
            size: 36,
            color: PomuColors.primary,
          ),
          const SizedBox(height: PomuSpacing.sm),
          Text(
            hasScanned
                ? context.l10n.noRemainingDuplicateCandidates
                : context.l10n.noAnalysisResult,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasScanned
                ? context.l10n.scanAgainIfNewPhotos
                : context.l10n.tapFindCandidatesGuide,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: PomuColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
