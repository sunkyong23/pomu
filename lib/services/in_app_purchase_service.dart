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
    if (_isInitialized) {
      debugPrint('🟡 InAppPurchaseService: 이미 초기화되어 있어요.');
      return;
    }

    debugPrint('🟣 InAppPurchaseService 초기화 시작');

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('❌ purchaseStream 오류');
        debugPrint('❌ error: $error');
        debugPrint('❌ stackTrace: $stackTrace');

        _errorMessage = '결제 상태를 확인하지 못했어요.';
        _isPurchasing = false;
        _isRestoring = false;

        notifyListeners();
      },
      onDone: () {
        debugPrint('🟡 purchaseStream 종료');
      },
    );

    _isInitialized = true;

    await loadProducts();

    debugPrint('🟢 InAppPurchaseService 초기화 완료');
  }

  Future<void> loadProducts() async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('🛍️ StoreKit 상품 조회 시작');
    debugPrint('🛍️ 요청 Product ID: $duplicateCleanupProductId');
    debugPrint('========================================');

    _setLoading(true);
    _errorMessage = null;

    try {
      _isStoreAvailable = await _inAppPurchase.isAvailable();

      debugPrint('🛍️ Store available: $_isStoreAvailable');

      if (!_isStoreAvailable) {
        _duplicateCleanupProduct = null;
        _errorMessage = '현재 App Store 결제를 사용할 수 없어요.';

        debugPrint('❌ App Store 결제를 사용할 수 없음');
        return;
      }

      final response = await _inAppPurchase.queryProductDetails({
        duplicateCleanupProductId,
      });

      debugPrint('');
      debugPrint('========================');
      debugPrint('Store available: $_isStoreAvailable');
      debugPrint('Found: ${response.productDetails.length}');
      debugPrint('Not Found: ${response.notFoundIDs}');
      debugPrint('Error: ${response.error}');

      for (final product in response.productDetails) {
        debugPrint('Product: ${product.id}');
        debugPrint('Title: ${product.title}');
        debugPrint('Price: ${product.price}');
        debugPrint('Currency: ${product.currencyCode}');
      }

      debugPrint('========================');
      debugPrint('');

      if (response.error != null) {
        _duplicateCleanupProduct = null;
        _errorMessage = response.error?.message ?? '상품 정보를 불러오지 못했어요.';

        debugPrint('❌ 상품 조회 응답 오류: ${response.error}');
        return;
      }

      if (response.productDetails.isEmpty) {
        _duplicateCleanupProduct = null;

        if (response.notFoundIDs.contains(duplicateCleanupProductId)) {
          _errorMessage = 'App Store에서 결제 상품을 찾지 못했어요.';
        } else {
          _errorMessage = '등록된 결제 상품이 없어요.';
        }

        debugPrint('❌ 상품이 비어 있음');
        debugPrint('❌ notFoundIDs: ${response.notFoundIDs}');
        return;
      }

      ProductDetails? matchedProduct;

      for (final product in response.productDetails) {
        if (product.id == duplicateCleanupProductId) {
          matchedProduct = product;
          break;
        }
      }

      _duplicateCleanupProduct =
          matchedProduct ?? response.productDetails.first;

      debugPrint('✅ 상품 저장 완료');
      debugPrint('✅ id: ${_duplicateCleanupProduct?.id}');
      debugPrint('✅ price: ${_duplicateCleanupProduct?.price}');
    } catch (error, stackTrace) {
      debugPrint('❌ loadProducts 예외 발생');
      debugPrint('❌ error: $error');
      debugPrint('❌ stackTrace: $stackTrace');

      _duplicateCleanupProduct = null;
      _errorMessage = '상품 정보를 불러오는 중 문제가 발생했어요.';
    } finally {
      _setLoading(false);

      debugPrint('🛍️ StoreKit 상품 조회 종료');
      debugPrint('');
    }
  }

  Future<bool> buyDuplicateCleanup() async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('🚀 buyDuplicateCleanup 호출');
    debugPrint('========================================');

    final product = _duplicateCleanupProduct;

    debugPrint('🚀 store available: $_isStoreAvailable');
    debugPrint('🚀 isPurchasing: $_isPurchasing');
    debugPrint('🚀 product: ${product?.id}');
    debugPrint('🚀 price: ${product?.price}');

    if (product == null || !_isStoreAvailable) {
      debugPrint('❌ 상품 또는 Store 사용 불가');
      debugPrint('❌ product null: ${product == null}');
      debugPrint('❌ store available: $_isStoreAvailable');

      _errorMessage = '구매할 상품 정보를 아직 불러오지 못했어요.';
      notifyListeners();

      return false;
    }

    if (_isPurchasing) {
      debugPrint('🟡 이미 결제가 진행 중이라 중복 호출을 막았어요.');
      return false;
    }

    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);

      debugPrint('🔥 buyNonConsumable 호출 직전');
      debugPrint('🔥 product ID: ${product.id}');
      debugPrint('🔥 product price: ${product.price}');

      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      debugPrint('🔥 buyNonConsumable 호출 완료');
      debugPrint('🔥 started: $started');

      if (!started) {
        _isPurchasing = false;
        _errorMessage = '결제를 시작하지 못했어요.';

        debugPrint('❌ StoreKit이 결제 시작 요청을 거절했어요.');

        notifyListeners();
      } else {
        debugPrint('✅ StoreKit 결제 요청 시작 성공');
        debugPrint('✅ 이제 purchaseStream 응답을 기다려요.');
      }

      return started;
    } catch (error, stackTrace) {
      debugPrint('❌ buyNonConsumable 예외 발생');
      debugPrint('❌ error: $error');
      debugPrint('❌ stackTrace: $stackTrace');

      _isPurchasing = false;
      _errorMessage = '결제를 시작하는 중 문제가 발생했어요.';

      notifyListeners();

      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (_isRestoring) {
      debugPrint('🟡 이미 구매 복원을 진행 중이에요.');
      return;
    }

    debugPrint('');
    debugPrint('========================================');
    debugPrint('♻️ 구매 복원 시작');
    debugPrint('========================================');

    _isRestoring = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();

      debugPrint('✅ restorePurchases 호출 완료');
      debugPrint('✅ purchaseStream 응답을 기다려요.');
    } catch (error, stackTrace) {
      debugPrint('❌ 구매 복원 예외 발생');
      debugPrint('❌ error: $error');
      debugPrint('❌ stackTrace: $stackTrace');

      _isRestoring = false;
      _errorMessage = '구매 내역을 복원하지 못했어요.';

      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('📦 purchaseStream 업데이트 수신');
    debugPrint('📦 purchase count: ${purchases.length}');
    debugPrint('========================================');

    if (purchases.isEmpty) {
      debugPrint('🟡 구매 업데이트가 비어 있어요.');

      _isPurchasing = false;
      _isRestoring = false;

      notifyListeners();
      return;
    }

    for (final purchase in purchases) {
      debugPrint('');
      debugPrint('📦 productID: ${purchase.productID}');
      debugPrint('📦 status: ${purchase.status}');
      debugPrint(
        '📦 pendingCompletePurchase: '
        '${purchase.pendingCompletePurchase}',
      );
      debugPrint('📦 error: ${purchase.error}');
      debugPrint('📦 purchaseID: ${purchase.purchaseID}');
      debugPrint('📦 transactionDate: ${purchase.transactionDate}');

      if (purchase.productID != duplicateCleanupProductId) {
        debugPrint('🟡 포무 상품이 아닌 구매 업데이트예요.');

        await _completePurchaseIfNeeded(purchase);
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('⏳ 결제 승인 대기 중');

          _isPurchasing = true;
          break;

        case PurchaseStatus.purchased:
          debugPrint('✅ 구매 완료 상태 수신');

          final isValid = await _verifyPurchase(purchase);

          if (isValid) {
            debugPrint('✅ 구매 검증 성공');

            await PurchaseAccessService.instance
                .markDuplicateCleanupPurchased();

            _errorMessage = null;
          } else {
            debugPrint('❌ 구매 검증 실패');

            _errorMessage = '구매 확인에 실패했어요.';
          }

          _isPurchasing = false;
          _isRestoring = false;
          break;

        case PurchaseStatus.restored:
          debugPrint('♻️ 구매 복원 상태 수신');

          final isValid = await _verifyPurchase(purchase);

          if (isValid) {
            debugPrint('✅ 복원 구매 검증 성공');

            await PurchaseAccessService.instance
                .markDuplicateCleanupPurchased();

            _errorMessage = null;
          } else {
            debugPrint('❌ 복원 구매 검증 실패');

            _errorMessage = '구매 확인에 실패했어요.';
          }

          _isPurchasing = false;
          _isRestoring = false;
          break;

        case PurchaseStatus.error:
          debugPrint('❌ 구매 오류 상태 수신');
          debugPrint('❌ purchase error: ${purchase.error}');

          _isPurchasing = false;
          _isRestoring = false;
          _errorMessage = purchase.error?.message ?? '결제를 완료하지 못했어요.';
          break;

        case PurchaseStatus.canceled:
          debugPrint('🟡 사용자가 결제를 취소했어요.');

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
    debugPrint('');
    debugPrint('🔍 구매 검증 시작');
    debugPrint('🔍 productID: ${purchase.productID}');
    debugPrint('🔍 status: ${purchase.status}');

    /*
     * 현재 1차 구현에서는 App Store가 전달한 purchased/restored 상태를
     * 정상 구매로 처리한다.
     *
     * 출시 전에는 영수증 또는 서버 검증을 추가하는 것이 더 안전하다.
     */

    final isValid =
        purchase.productID == duplicateCleanupProductId &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored);

    debugPrint('🔍 검증 결과: $isValid');

    return isValid;
  }

  Future<void> _completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) {
      debugPrint('🟡 completePurchase가 필요하지 않아요.');
      return;
    }

    debugPrint('🔵 completePurchase 호출 시작');

    try {
      await _inAppPurchase.completePurchase(purchase);

      debugPrint('✅ completePurchase 완료');
    } catch (error, stackTrace) {
      debugPrint('❌ completePurchase 오류');
      debugPrint('❌ error: $error');
      debugPrint('❌ stackTrace: $stackTrace');

      _errorMessage = '구매 완료 처리 중 문제가 발생했어요.';
    }
  }

  void clearError() {
    if (_errorMessage == null) return;

    debugPrint('🧹 결제 오류 메시지 초기화');

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🟣 InAppPurchaseService dispose');

    _purchaseSubscription?.cancel();

    super.dispose();
  }
}
