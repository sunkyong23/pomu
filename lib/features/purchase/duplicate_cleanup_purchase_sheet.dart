import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/purchase_access_service.dart';

Future<bool> showDuplicateCleanupPurchaseSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const DuplicateCleanupPurchaseSheet(),
  );

  return result ?? false;
}

class DuplicateCleanupPurchaseSheet extends StatefulWidget {
  const DuplicateCleanupPurchaseSheet({super.key});

  @override
  State<DuplicateCleanupPurchaseSheet> createState() =>
      _DuplicateCleanupPurchaseSheetState();
}

class _DuplicateCleanupPurchaseSheetState
    extends State<DuplicateCleanupPurchaseSheet> {
  final InAppPurchaseService _purchaseService = InAppPurchaseService.instance;

  final PurchaseAccessService _accessService = PurchaseAccessService.instance;

  @override
  void initState() {
    super.initState();

    _purchaseService.addListener(_handleServiceChanged);
    _accessService.addListener(_handleServiceChanged);

    if (_purchaseService.duplicateCleanupProduct == null &&
        !_purchaseService.isLoading) {
      _purchaseService.loadProducts();
    }
  }

  @override
  void dispose() {
    _purchaseService.removeListener(_handleServiceChanged);
    _accessService.removeListener(_handleServiceChanged);
    super.dispose();
  }

  void _handleServiceChanged() {
    if (!mounted) return;

    if (_accessService.isDuplicateCleanupPurchased) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {});
  }

  Future<void> _purchase() async {
    _purchaseService.clearError();
    await _purchaseService.buyDuplicateCleanup();
  }

  Future<void> _restore() async {
    _purchaseService.clearError();

    await _purchaseService.restorePurchases();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('구매 내역을 확인하고 있어요.')));
  }

  Future<void> _reloadProducts() async {
    _purchaseService.clearError();
    await _purchaseService.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final product = _purchaseService.duplicateCleanupProduct;

    final hasProductError =
        product == null && _purchaseService.errorMessage != null;

    final isBusy =
        _purchaseService.isLoading ||
        _purchaseService.isPurchasing ||
        _purchaseService.isRestoring;

    return Container(
      padding: EdgeInsets.only(
        left: PomuSpacing.lg,
        right: PomuSpacing.lg,
        top: PomuSpacing.md,
        bottom: MediaQuery.paddingOf(context).bottom + PomuSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: PomuColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              const SizedBox(height: PomuSpacing.lg),

              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: PomuColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_delete_rounded,
                  size: 34,
                  color: PomuColors.primary,
                ),
              ),

              const SizedBox(height: PomuSpacing.md),

              const Text(
                '중복 사진 정리를\n계속 이용해보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                '첫 번째 중복 그룹은 무료로 정리했어요.\n'
                '이제 한 번 구매하면 계속 이용할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: PomuColors.textSecondary,
                ),
              ),

              const SizedBox(height: PomuSpacing.lg),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PomuSpacing.lg),
                decoration: BoxDecoration(
                  color: PomuColors.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: PomuColors.divider),
                ),
                child: const Column(
                  children: [
                    _BenefitRow(
                      icon: Icons.all_inclusive_rounded,
                      title: '한 번 구매로 영구 이용',
                    ),
                    SizedBox(height: PomuSpacing.md),
                    _BenefitRow(
                      icon: Icons.collections_rounded,
                      title: '중복 그룹 개수 제한 없음',
                    ),
                    SizedBox(height: PomuSpacing.md),
                    _BenefitRow(icon: Icons.restore_rounded, title: '구매 복원 지원'),
                    SizedBox(height: PomuSpacing.md),
                    _BenefitRow(
                      icon: Icons.subscriptions_outlined,
                      title: '구독 없음',
                    ),
                  ],
                ),
              ),

              if (_purchaseService.errorMessage != null) ...[
                const SizedBox(height: PomuSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(PomuSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _purchaseService.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: PomuSpacing.lg),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : hasProductError
                      ? _reloadProducts
                      : _purchaseService.canPurchase
                      ? _purchase
                      : null,
                  child: _purchaseService.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : _purchaseService.isPurchasing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          hasProductError
                              ? '상품 정보 다시 불러오기'
                              : product == null
                              ? '상품 정보 불러오는 중...'
                              : '${product.price} · 영구 이용하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: PomuSpacing.sm),

              TextButton(
                onPressed: isBusy ? null : _restore,
                child: _purchaseService.isRestoring
                    ? const Text('구매 내역 확인 중...')
                    : const Text('이전에 구매했다면 복원'),
              ),

              TextButton(
                onPressed: isBusy
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text(
                  '나중에',
                  style: TextStyle(color: PomuColors.textSecondary),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                '결제는 Apple ID를 통해 진행됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: PomuColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _BenefitRow({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: PomuColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: PomuColors.primary),
        ),
        const SizedBox(width: PomuSpacing.md),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
