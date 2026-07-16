import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/purchase_access_service.dart';

import '../../l10n/app_localizations.dart';

Future<bool> showDuplicateCleanupPurchaseSheet(BuildContext context) async {
  debugPrint('🟣 구매 페이지 열기 시작');

  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (pageContext) {
        debugPrint('🟢 구매 페이지 builder 실행');

        return const Scaffold(
          backgroundColor: PomuColors.surface,
          body: SafeArea(child: DuplicateCleanupPurchaseSheet()),
        );
      },
    ),
  );

  debugPrint('🟡 구매 페이지 닫힘: $result');

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
    debugPrint('');
    debugPrint('========================================');
    debugPrint('🔥 구매 버튼 눌림');
    debugPrint('========================================');

    _purchaseService.clearError();

    final started = await _purchaseService.buyDuplicateCleanup();

    debugPrint('🔥 구매 버튼 처리 결과: $started');
    debugPrint('');
  }

  Future<void> _restore() async {
    _purchaseService.clearError();

    await _purchaseService.restorePurchases();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).purchaseRestoring)),
    );
  }

  Future<void> _reloadProducts() async {
    _purchaseService.clearError();
    await _purchaseService.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = _purchaseService.duplicateCleanupProduct;

    final hasProductError =
        product == null && _purchaseService.errorMessage != null;

    final isBusy =
        _purchaseService.isLoading ||
        _purchaseService.isPurchasing ||
        _purchaseService.isRestoring;

    final priceText = product?.price;

    debugPrint(
      '🧾 구매 시트 build: '
      'product=${product?.id}, price=$priceText, busy=$isBusy',
    );

    return Container(
      width: double.infinity,
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

                  _BenefitGrid(),

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
                              ? l10n.purchaseRestoringShort
                              : l10n.restorePurchase,
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
                        child: Text(
                          l10n.later,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PomuColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    l10n.oneTimePurchase,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PomuColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    l10n.paymentThroughApple,
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
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String? priceText;

  const _HeaderSection({required this.priceText});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
          child: Text(
            l10n.purchaseLifetimeBadge,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: PomuColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          l10n.purchaseTitle,
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

        Text(
          l10n.purchaseDescription,
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
                priceText ?? l10n.purchaseLoadingProduct,
                style: TextStyle(
                  fontSize: priceText == null ? 18 : 30,
                  fontWeight: FontWeight.w900,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                l10n.purchaseOneTimeNoExtraCharge,
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
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PomuSpacing.md),
      decoration: BoxDecoration(
        color: PomuColors.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BenefitTile(
                  icon: Icons.all_inclusive_rounded,
                  title: l10n.purchaseBenefitLifetimeTitle,
                  description: l10n.purchaseBenefitLifetimeDescription,
                ),
              ),
              SizedBox(width: PomuSpacing.sm),
              Expanded(
                child: _BenefitTile(
                  icon: Icons.collections_rounded,
                  title: l10n.purchaseBenefitUnlimitedTitle,
                  description: l10n.purchaseBenefitUnlimitedDescription,
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
                  title: l10n.purchaseBenefitRestoreTitle,
                  description: l10n.purchaseBenefitRestoreDescription,
                ),
              ),
              SizedBox(width: PomuSpacing.sm),
              Expanded(
                child: _BenefitTile(
                  icon: Icons.subscriptions_outlined,
                  title: l10n.purchaseBenefitNoSubscriptionTitle,
                  description: l10n.purchaseBenefitNoSubscriptionDescription,
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

          const SizedBox(height: 18),

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
              _buildFriendlyErrorMessage(context, message),
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

  String _buildFriendlyErrorMessage(BuildContext context, String rawMessage) {
    if (rawMessage.contains('StoreKit') || rawMessage.contains('platform')) {
      return AppLocalizations.of(context).purchaseLoadFailed;
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
    final l10n = AppLocalizations.of(context);
    String buttonText;

    if (hasProductError) {
      buttonText = l10n.purchaseReloadProduct;
    } else if (priceText == null) {
      buttonText = l10n.purchaseLoadingProduct;
    } else {
      buttonText = l10n.purchaseWithPrice(priceText!);
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
