import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_access_service.dart';

class InAppPurchaseService extends ChangeNotifier {
  InAppPurchaseService._();

  static final InAppPurchaseService instance = InAppPurchaseService._();

  static const String duplicateCleanupProductId =
      'com.sunkyung.pomu.duplicate_cleanup_lifetime';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isInitialized = false;
  bool _isStoreAvailable = false;
  bool _isLoading = false;
  bool _isPurchasing = false;
  bool _isRestoring = false;

  ProductDetails? _duplicateCleanupProduct;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isStoreAvailable => _isStoreAvailable;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoring => _isRestoring;

  ProductDetails? get duplicateCleanupProduct => _duplicateCleanupProduct;

  String? get errorMessage => _errorMessage;

  String? get displayPrice => _duplicateCleanupProduct?.price;

  bool get canPurchase =>
      _isStoreAvailable && _duplicateCleanupProduct != null && !_isPurchasing;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _errorMessage = '결제 상태를 확인하지 못했어요.';
        _isPurchasing = false;
        _isRestoring = false;
        notifyListeners();
      },
    );

    _isInitialized = true;

    await loadProducts();
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _isStoreAvailable = await _inAppPurchase.isAvailable();

      if (!_isStoreAvailable) {
        _duplicateCleanupProduct = null;
        _errorMessage = '현재 App Store 결제를 사용할 수 없어요.';
        return;
      }

      final response = await _inAppPurchase.queryProductDetails({
        duplicateCleanupProductId,
      });

      if (response.error != null) {
        _duplicateCleanupProduct = null;
        _errorMessage = response.error?.message ?? '상품 정보를 불러오지 못했어요.';
        return;
      }

      if (response.productDetails.isEmpty) {
        _duplicateCleanupProduct = null;

        if (response.notFoundIDs.contains(duplicateCleanupProductId)) {
          _errorMessage = 'App Store에서 결제 상품을 찾지 못했어요.';
        } else {
          _errorMessage = '등록된 결제 상품이 없어요.';
        }

        return;
      }

      _duplicateCleanupProduct = response.productDetails.firstWhere(
        (product) => product.id == duplicateCleanupProductId,
        orElse: () => response.productDetails.first,
      );
    } catch (error) {
      _duplicateCleanupProduct = null;
      _errorMessage = '상품 정보를 불러오는 중 문제가 발생했어요.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> buyDuplicateCleanup() async {
    final product = _duplicateCleanupProduct;

    if (product == null || !_isStoreAvailable) {
      _errorMessage = '구매할 상품 정보를 아직 불러오지 못했어요.';
      notifyListeners();
      return false;
    }

    if (_isPurchasing) return false;

    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);

      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!started) {
        _isPurchasing = false;
        _errorMessage = '결제를 시작하지 못했어요.';
        notifyListeners();
      }

      return started;
    } catch (error) {
      _isPurchasing = false;
      _errorMessage = '결제를 시작하는 중 문제가 발생했어요.';
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (_isRestoring) return;

    _isRestoring = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
    } catch (error) {
      _isRestoring = false;
      _errorMessage = '구매 내역을 복원하지 못했어요.';
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    if (purchases.isEmpty) {
      _isRestoring = false;
      notifyListeners();
      return;
    }

    for (final purchase in purchases) {
      if (purchase.productID != duplicateCleanupProductId) {
        await _completePurchaseIfNeeded(purchase);
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isPurchasing = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final isValid = await _verifyPurchase(purchase);

          if (isValid) {
            await PurchaseAccessService.instance
                .markDuplicateCleanupPurchased();

            _errorMessage = null;
          } else {
            _errorMessage = '구매 확인에 실패했어요.';
          }

          _isPurchasing = false;
          _isRestoring = false;
          break;

        case PurchaseStatus.error:
          _isPurchasing = false;
          _isRestoring = false;
          _errorMessage = purchase.error?.message ?? '결제를 완료하지 못했어요.';
          break;

        case PurchaseStatus.canceled:
          _isPurchasing = false;
          _isRestoring = false;
          _errorMessage = null;
          break;
      }

      await _completePurchaseIfNeeded(purchase);
    }

    notifyListeners();
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    /*
     * 현재 1차 구현에서는 App Store가 전달한 purchased/restored 상태를
     * 정상 구매로 처리한다.
     *
     * 출시 전에는 영수증 또는 서버 검증을 추가하는 것이 더 안전하다.
     */
    return purchase.productID == duplicateCleanupProductId &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored);
  }

  Future<void> _completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;

    try {
      await _inAppPurchase.completePurchase(purchase);
    } catch (error) {
      _errorMessage = '구매 완료 처리 중 문제가 발생했어요.';
    }
  }

  void clearError() {
    if (_errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
