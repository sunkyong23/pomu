import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/purchase_access_service.dart';

Future<bool> showDuplicateCleanupPurchaseSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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

    final priceText = product?.price;

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: const BoxDecoration(
          color: PomuColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: PomuColors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  PomuSpacing.lg,
                  PomuSpacing.lg,
                  PomuSpacing.lg,
                  MediaQuery.paddingOf(context).bottom + PomuSpacing.lg,
                ),
                child: Column(
                  children: [
                    _HeaderSection(priceText: priceText),

                    const SizedBox(height: PomuSpacing.lg),

                    const _BenefitGrid(),

                    if (_purchaseService.errorMessage != null) ...[
                      const SizedBox(height: PomuSpacing.md),
                      _ErrorCard(message: _purchaseService.errorMessage!),
                    ],

                    const SizedBox(height: PomuSpacing.lg),

                    _PrimaryPurchaseButton(
                      isBusy: isBusy,
                      isLoading: _purchaseService.isLoading,
                      isPurchasing: _purchaseService.isPurchasing,
                      hasProductError: hasProductError,
                      canPurchase: _purchaseService.canPurchase,
                      priceText: priceText,
                      onPurchase: _purchase,
                      onReload: _reloadProducts,
                    ),

                    const SizedBox(height: PomuSpacing.sm),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: isBusy ? null : _restore,
                          child: Text(
                            _purchaseService.isRestoring
                                ? '구매 내역 확인 중...'
                                : '구매 복원',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: PomuColors.divider,
                        ),

                        TextButton(
                          onPressed: isBusy
                              ? null
                              : () {
                                  Navigator.of(context).pop(false);
                                },
                          child: const Text(
                            '나중에',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: PomuColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      '구독이 아닌 일회성 구매예요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PomuColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '결제는 Apple ID를 통해 진행됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: PomuColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String? priceText;

  const _HeaderSection({required this.priceText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
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

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: PomuColors.primaryLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '한 번 구매로 영구 이용',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: PomuColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          '중복 사진 정리를\n계속 이용해보세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            height: 1.22,
            fontWeight: FontWeight.w900,
            color: PomuColors.textPrimary,
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          '첫 번째 중복 그룹은 무료로 정리했어요.\n'
          '이제 제한 없이 계속 정리할 수 있어요.',
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
          padding: const EdgeInsets.symmetric(
            horizontal: PomuSpacing.lg,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: PomuColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: PomuColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Text(
                priceText ?? '상품 정보 확인 중',
                style: TextStyle(
                  fontSize: priceText == null ? 18 : 30,
                  fontWeight: FontWeight.w900,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                '일회성 결제 · 추가 결제 없음',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PomuColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitGrid extends StatelessWidget {
  const _BenefitGrid();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PomuSpacing.md),
      decoration: BoxDecoration(
        color: PomuColors.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BenefitTile(
                  icon: Icons.all_inclusive_rounded,
                  title: '영구 이용',
                  description: '한 번만 결제',
                ),
              ),
              SizedBox(width: PomuSpacing.sm),
              Expanded(
                child: _BenefitTile(
                  icon: Icons.collections_rounded,
                  title: '무제한 정리',
                  description: '그룹 개수 제한 없음',
                ),
              ),
            ],
          ),

          SizedBox(height: PomuSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _BenefitTile(
                  icon: Icons.restore_rounded,
                  title: '구매 복원',
                  description: '재설치 후에도 복원',
                ),
              ),
              SizedBox(width: PomuSpacing.sm),
              Expanded(
                child: _BenefitTile(
                  icon: Icons.subscriptions_outlined,
                  title: '구독 없음',
                  description: '매달 결제하지 않아요',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: PomuColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: PomuColors.primary),
          ),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: PomuColors.textPrimary,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            description,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              color: PomuColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PomuSpacing.md,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 19, color: Colors.red),

          const SizedBox(width: PomuSpacing.sm),

          Expanded(
            child: Text(
              _buildFriendlyErrorMessage(message),
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildFriendlyErrorMessage(String rawMessage) {
    if (rawMessage.contains('StoreKit') || rawMessage.contains('platform')) {
      return '상품 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.';
    }

    return rawMessage;
  }
}

class _PrimaryPurchaseButton extends StatelessWidget {
  final bool isBusy;
  final bool isLoading;
  final bool isPurchasing;
  final bool hasProductError;
  final bool canPurchase;
  final String? priceText;
  final VoidCallback onPurchase;
  final VoidCallback onReload;

  const _PrimaryPurchaseButton({
    required this.isBusy,
    required this.isLoading,
    required this.isPurchasing,
    required this.hasProductError,
    required this.canPurchase,
    required this.priceText,
    required this.onPurchase,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText;

    if (hasProductError) {
      buttonText = '상품 정보 다시 불러오기';
    } else if (priceText == null) {
      buttonText = '상품 정보 불러오는 중...';
    } else {
      buttonText = '$priceText으로 영구 이용';
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isBusy
            ? null
            : hasProductError
            ? onReload
            : canPurchase
            ? onPurchase
            : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: PomuColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PomuColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading || isPurchasing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}
