import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../models/duplicate_photo_group.dart';
import '../../services/duplicate_detector_service.dart';

class DuplicateCandidatesScreen extends StatefulWidget {
  const DuplicateCandidatesScreen({super.key});

  @override
  State<DuplicateCandidatesScreen> createState() =>
      _DuplicateCandidatesScreenState();
}

class _DuplicateCandidatesScreenState extends State<DuplicateCandidatesScreen> {
  final DuplicateDetectorService _service = DuplicateDetectorService();

  bool _isLoading = false;
  int _progressCurrent = 0;
  int _progressTotal = 0;
  List<DuplicatePhotoGroup> _groups = [];

  Future<void> _scan() async {
    setState(() {
      _isLoading = true;
      _groups = [];
      _progressCurrent = 0;
      _progressTotal = 0;
    });

    final groups = await _service.findDuplicateCandidates(
      limit: 1000,
      onProgress: (current, total) {
        if (!mounted) return;

        setState(() {
          _progressCurrent = current;
          _progressTotal = total;
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  int get _deleteCandidateCount {
    return _groups.fold(0, (sum, group) => sum + group.deleteCandidateCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            text: _isLoading ? '분석 중...' : '중복 후보 찾기',
            icon: Icons.cleaning_services_rounded,
            onPressed: _isLoading ? null : _scan,
          ),
          const SizedBox(height: PomuSpacing.xl),
          if (_isLoading)
            _ProgressCard(current: _progressCurrent, total: _progressTotal)
          else if (_groups.isNotEmpty) ...[
            _SummaryCard(
              groupCount: _groups.length,
              deleteCandidateCount: _deleteCandidateCount,
            ),
            const SizedBox(height: PomuSpacing.lg),
            ..._groups.map((group) => _DuplicateGroupCard(group: group)),
          ] else
            const _EmptyCard(),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressCard({required this.current, required this.total});

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
          const Text(
            '중복 사진 분석 중...',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            color: PomuColors.primary,
            backgroundColor: PomuColors.primaryLight,
          ),
          const SizedBox(height: PomuSpacing.md),
          Text(
            hasProgress
                ? '$percent% · $current / $total 그룹 분석 중'
                : '중복 후보를 찾고 있어요.',
            style: const TextStyle(
              fontSize: 14,
              color: PomuColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '사진이 많을수록 조금 시간이 걸릴 수 있어요.',
            style: TextStyle(
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
  final int groupCount;
  final int deleteCandidateCount;

  const _SummaryCard({
    required this.groupCount,
    required this.deleteCandidateCount,
  });

  @override
  Widget build(BuildContext context) {
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
              '중복 후보 $groupCount개 그룹\n삭제 후보 $deleteCandidateCount장',
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

  const _DuplicateGroupCard({required this.group});

  @override
  State<_DuplicateGroupCard> createState() => _DuplicateGroupCardState();
}

class _DuplicateGroupCardState extends State<_DuplicateGroupCard> {
  late final Set<String> _keeperAssetIds;

  @override
  void initState() {
    super.initState();

    _keeperAssetIds = {widget.group.keeper.id};
  }

  void _toggleKeeper(AssetEntity asset) {
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

  @override
  Widget build(BuildContext context) {
    final keeperCount = _keeperAssetIds.length;
    final selectedCount = widget.group.assets.length - keeperCount;

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
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.group.assets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final asset = widget.group.assets[index];

                final isKeeper = _keeperAssetIds.contains(asset.id);
                final isDeleteCandidate = !isKeeper;

                return GestureDetector(
                  onTap: () => _toggleKeeper(asset),
                  child: _SelectableThumbnailTile(
                    asset: asset,
                    isKeeper: isKeeper,
                    isSelected: isDeleteCandidate,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          OutlinedButton.icon(
            onPressed: widget.group.assets.length <= 1
                ? null
                : () {
                    final deleteIds = widget.group.assets
                        .where((asset) => !_keeperAssetIds.contains(asset.id))
                        .map((asset) => asset.id)
                        .toList();
                    debugPrint('🧪 선택된 삭제 후보 로그: ${deleteIds.join(', ')}');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '삭제 후보 ${deleteIds.length}장을 확인했어요. 아직 실제 삭제는 하지 않아요.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(
              selectedCount == 0 ? '삭제할 사진 없음' : '삭제 후보 $selectedCount장 확인',
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
  final bool isSelected;

  const _SelectableThumbnailTile({
    required this.asset,
    required this.isKeeper,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isKeeper ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: isKeeper || isSelected ? 1 : 0.55,
        duration: const Duration(milliseconds: 180),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.all(isKeeper ? 3 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isKeeper ? PomuColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
            ),
            Positioned(
              left: 7,
              top: 7,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: isKeeper ? PomuColors.primary : Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isKeeper ? '⭐ 보관' : '삭제 후보',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 7,
              bottom: 7,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isKeeper ? PomuColors.primary : Colors.white70,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isKeeper ? PomuColors.primary : PomuColors.divider,
                  ),
                ),
                child: Icon(
                  isKeeper ? Icons.star_rounded : Icons.delete_outline_rounded,
                  size: 16,
                  color: isKeeper ? Colors.white : PomuColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: const Text(
        '아직 분석 결과가 없어요.\n중복 후보 찾기를 눌러주세요.',
        style: TextStyle(
          fontSize: 15,
          color: PomuColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}
