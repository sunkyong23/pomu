import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../../models/photo_category.dart';
import '../../services/scan_service.dart';
import '../home/home_screen.dart';

class ScanProgressScreen extends StatefulWidget {
  const ScanProgressScreen({super.key});

  @override
  State<ScanProgressScreen> createState() => _ScanProgressScreenState();
}

class _ScanProgressScreenState extends State<ScanProgressScreen> {
  final ScanService _scanService = ScanService();

  int _step = 0;
  ScanResult? _result;

  final List<String> _messages = const [
    '새 사진을 확인하고 있어요',
    'AI가 사진을 분석하고 있어요',
    '앨범을 준비하고 있어요',
    '정리가 완료됐어요',
  ];

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

    return Scaffold(
      backgroundColor: PomuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              PomuLogo(size: isComplete ? 72 : 96),
              const SizedBox(height: PomuSpacing.xl),
              Text(
                isComplete ? '정리가 완료됐어요' : '사진을 정리하고 있어요',
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
                    _messages[_step],
                    key: ValueKey(_messages[_step]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                ),
              SizedBox(height: isComplete ? PomuSpacing.xl : PomuSpacing.xl),
              if (isComplete)
                _CompleteSummary(result: _result!)
              else
                _StepIndicator(currentStep: _step),
              const Spacer(),
              if (isComplete)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _goHome,
                    child: const Text(
                      '홈으로 돌아가기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
    final items = ['사진 확인', 'AI 분석', '앨범 생성'];

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
            color: Colors.black.withOpacity(0.045),
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
            '${result.totalCount}장 정리 완료',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: PomuSpacing.xs),
          Text(
            '${result.albumCount}개 앨범으로 분류했어요',
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
                      entry.key.koreanName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PomuColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value.length}장',
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
