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
  List<DuplicatePhotoGroup> _groups = [];

  Future<void> _scan() async {
    setState(() => _isLoading = true);

    final groups = await _service.findDuplicateCandidates(limit: 1000);

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
            const Center(
              child: Padding(
                padding: EdgeInsets.all(PomuSpacing.xl),
                child: CircularProgressIndicator(color: PomuColors.primary),
              ),
            )
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

class _DuplicateGroupCard extends StatelessWidget {
  final DuplicatePhotoGroup group;

  const _DuplicateGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
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
            '중복 후보 ${group.count}장',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '보관 1장 · 삭제 후보 ${group.deleteCandidateCount}장',
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
              itemCount: group.assets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final asset = group.assets[index];
                final isKeeper = index == 0;

                return _ThumbnailTile(asset: asset, isKeeper: isKeeper);
              },
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              debugPrint(
                '🧪 삭제 후보 로그: ${group.deleteCandidates.map((e) => e.id).join(', ')}',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('아직 실제 삭제는 하지 않아요. 로그만 남겼어요.')),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('삭제 후보 확인'),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  final AssetEntity asset;
  final bool isKeeper;

  const _ThumbnailTile({required this.asset, required this.isKeeper});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: FutureBuilder(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(220, 220)),
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
        Positioned(
          left: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: isKeeper ? PomuColors.mint : Colors.black54,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isKeeper ? '보관' : '삭제 후보',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
