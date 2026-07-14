import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../models/duplicate_photo_group.dart';
import '../../services/duplicate_detector_service.dart';
import '../../services/duplicate_history_service.dart';
import '../../services/duplicate_result_cache_service.dart';
import '../../services/duplicate_summary_service.dart';
import '../../services/purchase_access_service.dart';
import '../purchase/duplicate_cleanup_purchase_sheet.dart';

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('마지막 검사 결과를 불러오지 못했어요: $e')));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('중복 후보를 더 불러오지 못했어요: $e')));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('중복 사진 분석 중 문제가 발생했어요: $e')));
    }
  }

  Future<void> _resolveGroup(
    DuplicatePhotoGroup resolvedGroup,
    List<String> remainingAssetIds,
    int deletedCount,
    int deletedBytes,
  ) async {
    if (_isSavingResult) return;

    final key = _buildGroupKeyFromIds(remainingAssetIds);

    final updatedGroups = _groups
        .where((group) => group.id != resolvedGroup.id)
        .toList();

    setState(() {
      _resolvedGroupKeys.add(key);
      _groups = updatedGroups;
      _isSavingResult = true;
    });

    try {
      await _historyService.saveResolvedGroup(key);
      await _resultCacheService.removeGroupById(resolvedGroup.id);

      final nextGroupCount = (_savedSummary.groupCount - 1).clamp(0, 1 << 31);
      final nextDeleteCandidateCount =
          (_savedSummary.deleteCandidateCount - deletedCount).clamp(0, 1 << 31);
      final nextReclaimableBytes =
          (_savedSummary.reclaimableBytes - deletedBytes).clamp(0, 1 << 63);

      await _summaryService.saveSummary(
        groupCount: nextGroupCount,
        deleteCandidateCount: nextDeleteCandidateCount,
        reclaimableBytes: nextReclaimableBytes,
      );

      final updatedSummary = await _summaryService.loadSummary();

      if (!mounted) return;

      setState(() {
        _savedSummary = updatedSummary;
        _isSavingResult = false;
        _totalCachedGroupCount = (_totalCachedGroupCount - 1).clamp(0, 1 << 31);
        _cachedGroupOffset = _cachedGroupOffset.clamp(
          0,
          _totalCachedGroupCount,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSavingResult = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 결과를 저장하는 중 문제가 발생했어요: $e')));
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
        ? '검사 결과를 저장하고 있어요. 잠시만 기다려주세요.'
        : '중복 사진을 분석하고 있어요. 잠시만 기다려주세요.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text(
            '중복 사진 정리',
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
              '비슷하게 보이는 사진을\n먼저 후보로 찾아볼게요.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
                height: 1.15,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: PomuSpacing.md),
            const Text(
              '지금은 삭제하지 않고, 보관할 사진과 삭제 후보만 보여줘요.',
              style: TextStyle(
                fontSize: 15,
                color: PomuColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: PomuSpacing.xl),

            PomuPrimaryButton(
              text: _isSavingResult
                  ? '결과 저장 중...'
                  : _isLoading
                  ? '분석 중...'
                  : _savedSummary.hasScanned
                  ? '다시 검사하기'
                  : '중복 후보 찾기',
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
                    label: Text(_isLoadingMore ? '불러오는 중...' : '중복 후보 더 보기'),
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
      child: const Row(
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
              '마지막 검사 결과를 불러오고 있어요.',
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
            isSavingResult ? '검사 결과 저장 중...' : '중복 사진 다시 분석 중...',
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
                ? '검사 결과를 안전하게 저장하고 있어요.'
                : hasProgress
                ? '$percent% · $current / $total 그룹 분석 중'
                : '중복 후보를 찾고 있어요.',
            style: const TextStyle(
              fontSize: 14,
              color: PomuColors.textSecondary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            isSavingResult
                ? '잠시 후 바로 정리를 계속할 수 있어요.'
                : '사진이 많을수록 조금 시간이 걸릴 수 있어요.',
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
                  ? '전체 중복 후보 $totalGroupCount개 그룹\n'
                        '현재 $visibleGroupCount개 표시 중 · '
                        '삭제 후보 $deleteCandidateCount장'
                  : '중복 후보 $totalGroupCount개 그룹\n'
                        '삭제 후보 $deleteCandidateCount장',
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('보관할 사진은 최소 1장 필요해요.')));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('구매가 완료됐어요. 삭제를 계속 진행할게요.')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('삭제가 취소되었거나 실패했어요.')));
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
              ? '${deletedIds.length}장의 사진을 삭제했어요. '
                    '첫 무료 정리를 사용했어요.'
              : '${deletedIds.length}장의 사진을 '
                    '최근 삭제된 항목으로 이동했어요.',
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

    final readableSize = _formatBytes(totalBytes);

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
                const Text(
                  '삭제 준비',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '삭제 후보 ${deleteAssets.length}장을 다시 확인해주세요.',
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
                    '예상 확보 공간 $readableSize',
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
                const Text(
                  '삭제한 사진은 최근 삭제된 항목으로 이동해요.',
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
                        child: const Text('취소'),
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
                        label: Text('${deleteAssets.length}장 삭제'),
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
      final file = await asset.file.timeout(const Duration(seconds: 1));

      if (file == null) {
        return 0;
      }

      return await file.length().timeout(const Duration(seconds: 1));
    } on TimeoutException {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '계산 중';

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
            '중복 후보 ${widget.group.count}장',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '보관 $keeperCount장 · 삭제 후보 $selectedCount장',
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
                  ? '삭제할 사진 없음'
                  : widget.isBusy
                  ? '결과 저장 중...'
                  : '삭제 준비 ($selectedCount장)',
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
                isKeeper ? '✓ 보관' : '삭제 후보',
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
            hasScanned ? '현재 남아 있는 중복 후보가 없어요' : '아직 분석 결과가 없어요',
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
                ? '새로운 사진이 추가되었다면\n다시 검사해주세요.'
                : '중복 후보 찾기를 눌러\n사진 보관함을 검사해주세요.',
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
