import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

enum _DuplicateGroupSortOption { newest, oldest, mostDuplicates }

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

  static const String _sortOptionPreferenceKey = 'duplicate_group_sort_option';

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

  _DuplicateGroupSortOption _savedSortOption =
      _DuplicateGroupSortOption.mostDuplicates;

  final Set<String> _resolvedGroupKeys = {};

  bool get _isBusy => _isLoading || _isSavingResult;
  bool get _hasMoreCachedGroups => _cachedGroupOffset < _totalCachedGroupCount;

  DateTime _getNewestGroupDate(DuplicatePhotoGroup group) {
    if (group.assets.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return group.assets
        .map((asset) => asset.createDateTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  DateTime _getOldestGroupDate(DuplicatePhotoGroup group) {
    if (group.assets.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return group.assets
        .map((asset) => asset.createDateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  void _sortGroups(
    List<DuplicatePhotoGroup> groups,
    _DuplicateGroupSortOption sortOption,
  ) {
    switch (sortOption) {
      case _DuplicateGroupSortOption.newest:
        groups.sort((a, b) {
          return _getNewestGroupDate(b).compareTo(_getNewestGroupDate(a));
        });
        break;

      case _DuplicateGroupSortOption.oldest:
        groups.sort((a, b) {
          return _getOldestGroupDate(a).compareTo(_getOldestGroupDate(b));
        });
        break;

      case _DuplicateGroupSortOption.mostDuplicates:
        groups.sort((a, b) {
          final countCompare = b.count.compareTo(a.count);

          if (countCompare != 0) {
            return countCompare;
          }

          // 중복 개수가 같으면 최신 그룹을 먼저 표시해요.
          return _getNewestGroupDate(b).compareTo(_getNewestGroupDate(a));
        });
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedSortOption();
    _loadInitialData();
  }

  String _buildGroupKeyFromIds(List<String> ids) {
    final sorted = [...ids]..sort();
    return sorted.join('|');
  }

  Future<void> _loadSavedSortOption() async {
    final preferences = await SharedPreferences.getInstance();
    final savedValue = preferences.getString(_sortOptionPreferenceKey);

    if (savedValue == null) return;

    var matchedOption = _DuplicateGroupSortOption.mostDuplicates;

    for (final option in _DuplicateGroupSortOption.values) {
      if (option.name == savedValue) {
        matchedOption = option;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      _savedSortOption = matchedOption;
    });
  }

  Future<void> _saveSortOption(_DuplicateGroupSortOption sortOption) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_sortOptionPreferenceKey, sortOption.name);

    if (!mounted) return;

    setState(() {
      _savedSortOption = sortOption;
    });
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

  Future<void> _showScanSortSheet() async {
    if (_isBusy || _isInitializing) return;

    var selectedOption = _savedSortOption;

    final result = await showModalBottomSheet<_DuplicateGroupSortOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      context.l10n.duplicateSortSheetTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PomuColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.duplicateSortSheetDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: PomuColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: PomuSpacing.lg),
                    _ScanSortOptionTile(
                      title: context.l10n.duplicateSortMostTitle,
                      description: context.l10n.duplicateSortMostDescription,
                      icon: Icons.filter_9_plus_rounded,
                      option: _DuplicateGroupSortOption.mostDuplicates,
                      selectedOption: selectedOption,
                      onChanged: (option) {
                        setSheetState(() {
                          selectedOption = option;
                        });
                      },
                    ),
                    const SizedBox(height: PomuSpacing.sm),
                    _ScanSortOptionTile(
                      title: context.l10n.duplicateSortNewestTitle,
                      description: context.l10n.duplicateSortNewestDescription,
                      icon: Icons.schedule_rounded,
                      option: _DuplicateGroupSortOption.newest,
                      selectedOption: selectedOption,
                      onChanged: (option) {
                        setSheetState(() {
                          selectedOption = option;
                        });
                      },
                    ),
                    const SizedBox(height: PomuSpacing.sm),
                    _ScanSortOptionTile(
                      title: context.l10n.duplicateSortOldestTitle,
                      description: context.l10n.duplicateSortOldestDescription,
                      icon: Icons.history_rounded,
                      option: _DuplicateGroupSortOption.oldest,
                      selectedOption: selectedOption,
                      onChanged: (option) {
                        setSheetState(() {
                          selectedOption = option;
                        });
                      },
                    ),
                    const SizedBox(height: PomuSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(selectedOption);
                        },
                        icon: const Icon(Icons.search_rounded),
                        label: Text(context.l10n.duplicateSortStartButton),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    await _saveSortOption(result);

    if (!mounted) return;

    await _scan(result);
  }

  Future<void> _scan(_DuplicateGroupSortOption sortOption) async {
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

      // 전체 결과를 사용자가 검사 전에 선택한 기준으로 먼저 정렬해요.
      _sortGroups(filteredGroups, sortOption);

      // 화면에는 첫 100개만 보여주고, 캐시에는 전체 결과를 저장해요.
      final initialVisibleGroups = filteredGroups.take(_cachePageSize).toList();

      // 사진 분석은 끝났지만 캐시와 대시보드 저장은 아직 진행 중이에요.
      setState(() {
        _groups = initialVisibleGroups;
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
        _cachedGroupOffset = initialVisibleGroups.length;
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
              onPressed: _isBusy || _isInitializing ? null : _showScanSortSheet,
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

class _ScanSortOptionTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final _DuplicateGroupSortOption option;
  final _DuplicateGroupSortOption selectedOption;
  final ValueChanged<_DuplicateGroupSortOption> onChanged;

  const _ScanSortOptionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.option,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = option == selectedOption;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onChanged(option);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(PomuSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? PomuColors.primaryLight : PomuColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? PomuColors.primary : PomuColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? PomuColors.primary
                      : PomuColors.primaryLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : PomuColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: PomuSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PomuColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PomuColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? PomuColors.primary
                    : PomuColors.textSecondary,
              ),
            ],
          ),
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

  Future<void> _showGroupPhotoViewer({required int initialIndex}) async {
    if (widget.isBusy) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (viewerContext) {
          return _DuplicateGroupViewerScreen(
            assets: widget.group.assets,
            initialIndex: initialIndex,
            initialKeeperAssetIds: _keeperAssetIds,
            onKeeperSelectionChanged: (updatedKeeperAssetIds) {
              if (!mounted) return;

              setState(() {
                _keeperAssetIds = updatedKeeperAssetIds;
              });
            },
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteEntireGroupRequest() async {
    if (widget.isBusy) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final photoCount = widget.group.assets.length;

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
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: PomuColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: PomuSpacing.lg),

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: PomuColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: PomuColors.primary,
                    size: 25,
                  ),
                ),

                const SizedBox(height: PomuSpacing.md),

                Text(
                  sheetContext.l10n.duplicateDeleteEntireTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  sheetContext.l10n.duplicateDeleteEntireDescription(
                    photoCount,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: PomuColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: PomuSpacing.md),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(PomuSpacing.md),
                  decoration: BoxDecoration(
                    color: PomuColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: PomuColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: PomuColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sheetContext.l10n.duplicateDeleteEntireWarning,
                          style: const TextStyle(
                            fontSize: 13,
                            color: PomuColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: PomuSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: PomuColors.textPrimary,
                          side: const BorderSide(color: PomuColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(sheetContext.l10n.cancel),
                      ),
                    ),

                    const SizedBox(width: PomuSpacing.sm),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: PomuColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        label: Text(
                          sheetContext.l10n.duplicateDeleteEntireButton(
                            photoCount,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
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

    if (!mounted || confirmed != true) return;

    await _handleDeleteRequest(widget.group.assets);
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
    final totalBytesFuture = Future<int>.delayed(
      const Duration(milliseconds: 400),
      () => _calculateTotalFileSize(deleteAssets),
    );

    if (!mounted) return;

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
                  child: FutureBuilder<int>(
                    future: totalBytesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PomuColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              sheetContext.l10n.duplicateCalculatingSpace,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: PomuColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      }

                      final readableSize = _formatBytes(
                        sheetContext,
                        snapshot.data ?? 0,
                      );

                      return Text(
                        sheetContext.l10n.estimatedSpace(readableSize),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: PomuColors.textPrimary,
                        ),
                      );
                    },
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
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.duplicateCandidateCount(widget.group.count),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              TextButton(
                onPressed: widget.isBusy
                    ? null
                    : _handleDeleteEntireGroupRequest,
                style: TextButton.styleFrom(
                  foregroundColor: PomuColors.textSecondary,
                  disabledForegroundColor: PomuColors.textSecondary.withValues(
                    alpha: 0.35,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  context.l10n.duplicateDeleteAllAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
                      : () => _showGroupPhotoViewer(initialIndex: index),
                  child: _SelectableThumbnailTile(
                    asset: asset,
                    isKeeper: isKeeper,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: PomuSpacing.md),

          const Divider(height: 1, thickness: 1, color: PomuColors.divider),

          const SizedBox(height: PomuSpacing.md),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: selectedCount == 0 || widget.isBusy
                  ? null
                  : () {
                      final deleteAssets = widget.group.assets
                          .where((asset) => !_keeperAssetIds.contains(asset.id))
                          .toList();

                      _handleDeleteRequest(deleteAssets);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: PomuColors.primaryLight,
                foregroundColor: PomuColors.primary,
                disabledBackgroundColor: PomuColors.primaryLight.withValues(
                  alpha: 0.55,
                ),
                disabledForegroundColor: PomuColors.primary.withValues(
                  alpha: 0.45,
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: PomuSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: PomuColors.primary.withValues(alpha: 0.18),
                  ),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: Text(
                selectedCount == 0
                    ? context.l10n.noPhotosToDelete
                    : widget.isBusy
                    ? context.l10n.duplicateSavingShort
                    : context.l10n.deleteSelectedPhotosCount(selectedCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateGroupViewerScreen extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;
  final Set<String> initialKeeperAssetIds;
  final ValueChanged<Set<String>> onKeeperSelectionChanged;

  const _DuplicateGroupViewerScreen({
    required this.assets,
    required this.initialIndex,
    required this.initialKeeperAssetIds,
    required this.onKeeperSelectionChanged,
  });

  @override
  State<_DuplicateGroupViewerScreen> createState() =>
      _DuplicateGroupViewerScreenState();
}

class _DuplicateGroupViewerScreenState
    extends State<_DuplicateGroupViewerScreen> {
  late final PageController _pageController;
  late Set<String> _keeperAssetIds;
  late List<TransformationController> _transformationControllers;

  final Map<int, Future<Uint8List?>> _imageFutures = {};

  int _currentIndex = 0;
  bool _isCurrentPageZoomed = false;

  AssetEntity get _currentAsset => widget.assets[_currentIndex];
  bool get _isCurrentKeeper => _keeperAssetIds.contains(_currentAsset.id);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _keeperAssetIds = {...widget.initialKeeperAssetIds};
    _transformationControllers = List.generate(
      widget.assets.length,
      (_) => TransformationController(),
    );

    for (var i = 0; i < _transformationControllers.length; i++) {
      _transformationControllers[i].addListener(() => _handleTransform(i));
    }

    _preloadNearbyImages(_currentIndex);
  }

  Future<Uint8List?> _loadImage(int index) {
    return _imageFutures.putIfAbsent(
      index,
      () => widget.assets[index].thumbnailDataWithSize(
        const ThumbnailSize(2200, 2200),
        quality: 95,
      ),
    );
  }

  void _preloadNearbyImages(int index) {
    _loadImage(index);

    if (index > 0) {
      _loadImage(index - 1);
    }

    if (index < widget.assets.length - 1) {
      _loadImage(index + 1);
    }
  }

  void _handleTransform(int index) {
    if (index != _currentIndex || !mounted) return;

    final scale = _transformationControllers[index].value.getMaxScaleOnAxis();
    final nextZoomed = scale > 1.01;

    if (_isCurrentPageZoomed != nextZoomed) {
      setState(() {
        _isCurrentPageZoomed = nextZoomed;
      });
    }
  }

  void _updateKeeperSelection(bool keep) {
    final updated = {..._keeperAssetIds};

    if (keep) {
      updated.add(_currentAsset.id);
    } else {
      if (updated.length == 1 && updated.contains(_currentAsset.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.duplicateKeeperMinimum)),
        );
        return;
      }

      updated.remove(_currentAsset.id);
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _keeperAssetIds = updated;
    });

    widget.onKeeperSelectionChanged({...updated});
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_currentIndex + 1} / ${widget.assets.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isCurrentKeeper
                              ? PomuColors.primary.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _isCurrentKeeper
                                ? PomuColors.primary
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCurrentKeeper
                                  ? Icons.check_circle_rounded
                                  : Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isCurrentKeeper
                                  ? context.l10n.keep
                                  : context.l10n.deleteCandidate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _isCurrentPageZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.assets.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _isCurrentPageZoomed =
                        _transformationControllers[index].value
                            .getMaxScaleOnAxis() >
                        1.01;
                  });

                  _preloadNearbyImages(index);
                },
                itemBuilder: (context, index) {
                  final asset = widget.assets[index];

                  return RepaintBoundary(
                    key: PageStorageKey<String>('duplicate-viewer-${asset.id}'),
                    child: Center(
                      child: FutureBuilder<Uint8List?>(
                        future: _loadImage(index),
                        builder: (context, snapshot) {
                          final imageBytes = snapshot.data;

                          if (imageBytes == null) {
                            return const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            );
                          }

                          return InteractiveViewer(
                            key: ValueKey<String>('interactive-${asset.id}'),
                            transformationController:
                                _transformationControllers[index],
                            minScale: 1,
                            maxScale: 5,
                            panEnabled: true,
                            clipBehavior: Clip.none,
                            boundaryMargin: const EdgeInsets.all(48),
                            child: Image.memory(
                              imageBytes,
                              key: ValueKey<String>('image-${asset.id}'),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.assets.length, (index) {
                  final selected = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: selected ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 160),
                      scale: _isCurrentKeeper ? 1 : 1.03,
                      child: OutlinedButton.icon(
                        onPressed: _isCurrentKeeper
                            ? () => _updateKeeperSelection(false)
                            : null,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: _isCurrentKeeper
                              ? Colors.white
                              : PomuColors.primary,
                        ),
                        label: Text(
                          context.l10n.deleteCandidate,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _isCurrentKeeper
                                ? Colors.white
                                : PomuColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _isCurrentKeeper
                              ? Colors.transparent
                              : PomuColors.primary.withValues(alpha: 0.14),
                          disabledBackgroundColor: PomuColors.primary
                              .withValues(alpha: 0.14),
                          disabledForegroundColor: PomuColors.primary,
                          side: BorderSide(
                            color: _isCurrentKeeper
                                ? Colors.white38
                                : PomuColors.primary,
                            width: _isCurrentKeeper ? 1.2 : 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 160),
                      scale: _isCurrentKeeper ? 1.03 : 1,
                      child: FilledButton.icon(
                        onPressed: _isCurrentKeeper
                            ? null
                            : () => _updateKeeperSelection(true),
                        icon: Icon(
                          Icons.check_circle_rounded,
                          color: _isCurrentKeeper
                              ? Colors.white
                              : Colors.white70,
                        ),
                        label: Text(
                          context.l10n.keep,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _isCurrentKeeper
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _isCurrentKeeper
                              ? PomuColors.primary
                              : Colors.white.withValues(alpha: 0.10),
                          disabledBackgroundColor: PomuColors.primary,
                          disabledForegroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
