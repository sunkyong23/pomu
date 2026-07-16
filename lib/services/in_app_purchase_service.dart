import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_access_service.dart';

enum PurchaseServiceError {
  purchaseStatusUnavailable,
  storeUnavailable,
  productLoadFailed,
  productNotFound,
  noRegisteredProducts,
  productUnavailable,
  purchaseStartFailed,
  purchaseVerificationFailed,
  purchaseFailed,
  restoreFailed,
  completionFailed,
}

class InAppPurchaseService extends ChangeNotifier {
  InAppPurchaseService._();

  static final InAppPurchaseService instance = InAppPurchaseService._();

  static const String duplicateCleanupProductId =
      'com.sunkyung.pomu.duplicate_cleanup_lifetime';

  static const Duration _restoreTimeout = Duration(seconds: 12);

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isInitialized = false;
  bool _isStoreAvailable = false;
  bool _isLoading = false;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  bool _isDisposed = false;

  ProductDetails? _duplicateCleanupProduct;
  PurchaseServiceError? _errorCode;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isStoreAvailable => _isStoreAvailable;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoring => _isRestoring;

  ProductDetails? get duplicateCleanupProduct => _duplicateCleanupProduct;

  PurchaseServiceError? get errorCode => _errorCode;

  /// Backward-compatible fallback text.
  ///
  /// User-facing widgets should prefer [errorCode] and resolve it through
  /// AppLocalizations. This value may contain a StoreKit diagnostic message.
  String? get errorMessage => _errorMessage;

  String? get displayPrice => _duplicateCleanupProduct?.price;

  bool get canPurchase =>
      _isStoreAvailable && _duplicateCleanupProduct != null && !_isPurchasing;

  void _notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<void> initialize() async {
    if (_isDisposed) return;

    if (_isInitialized) {
      _log('🟡 InAppPurchaseService: 이미 초기화되어 있어요.');
      return;
    }

    _log('🟣 InAppPurchaseService 초기화 시작');

    await _purchaseSubscription?.cancel();

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        _log('❌ purchaseStream 오류');
        _log('❌ error: $error');
        _log('❌ stackTrace: $stackTrace');

        _setError(
          PurchaseServiceError.purchaseStatusUnavailable,
          '결제 상태를 확인하지 못했어요.',
        );
        _isPurchasing = false;
        _isRestoring = false;

        _notifySafely();
      },
      onDone: () {
        _log('🟡 purchaseStream 종료');
      },
    );

    _isInitialized = true;

    await loadProducts();

    _log('🟢 InAppPurchaseService 초기화 완료');
  }

  Future<void> loadProducts() async {
    _log('');
    _log('========================================');
    _log('🛍️ StoreKit 상품 조회 시작');
    _log('🛍️ 요청 Product ID: $duplicateCleanupProductId');
    _log('========================================');

    _setLoading(true);
    _clearErrorState();

    try {
      _isStoreAvailable = await _inAppPurchase.isAvailable();

      _log('🛍️ Store available: $_isStoreAvailable');

      if (!_isStoreAvailable) {
        _duplicateCleanupProduct = null;
        _isPurchasing = false;
        _setError(
          PurchaseServiceError.storeUnavailable,
          '현재 App Store 결제를 사용할 수 없어요.',
        );

        _log('❌ App Store 결제를 사용할 수 없음');
        return;
      }

      final response = await _inAppPurchase.queryProductDetails({
        duplicateCleanupProductId,
      });

      _log('');
      _log('========================');
      _log('Store available: $_isStoreAvailable');
      _log('Found: ${response.productDetails.length}');
      _log('Not Found: ${response.notFoundIDs}');
      _log('Error: ${response.error}');

      for (final product in response.productDetails) {
        _log('Product: ${product.id}');
        _log('Title: ${product.title}');
        _log('Price: ${product.price}');
        _log('Currency: ${product.currencyCode}');
      }

      _log('========================');
      _log('');

      if (response.error != null) {
        _duplicateCleanupProduct = null;
        _setError(
          PurchaseServiceError.productLoadFailed,
          response.error?.message ?? '상품 정보를 불러오지 못했어요.',
        );

        _log('❌ 상품 조회 응답 오류: ${response.error}');
        return;
      }

      if (response.productDetails.isEmpty) {
        _duplicateCleanupProduct = null;

        if (response.notFoundIDs.contains(duplicateCleanupProductId)) {
          _setError(
            PurchaseServiceError.productNotFound,
            'App Store에서 결제 상품을 찾지 못했어요.',
          );
        } else {
          _setError(
            PurchaseServiceError.noRegisteredProducts,
            '등록된 결제 상품이 없어요.',
          );
        }

        _log('❌ 상품이 비어 있음');
        _log('❌ notFoundIDs: ${response.notFoundIDs}');
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

      _log('✅ 상품 저장 완료');
      _log('✅ id: ${_duplicateCleanupProduct?.id}');
      _log('✅ price: ${_duplicateCleanupProduct?.price}');
    } catch (error, stackTrace) {
      _log('❌ loadProducts 예외 발생');
      _log('❌ error: $error');
      _log('❌ stackTrace: $stackTrace');

      _duplicateCleanupProduct = null;
      _setError(
        PurchaseServiceError.productLoadFailed,
        '상품 정보를 불러오는 중 문제가 발생했어요.',
      );
    } finally {
      _setLoading(false);

      _log('🛍️ StoreKit 상품 조회 종료');
      _log('');
    }
  }

  Future<bool> buyDuplicateCleanup() async {
    _log('');
    _log('========================================');
    _log('🚀 buyDuplicateCleanup 호출');
    _log('========================================');

    final product = _duplicateCleanupProduct;

    _log('🚀 store available: $_isStoreAvailable');
    _log('🚀 isPurchasing: $_isPurchasing');
    _log('🚀 product: ${product?.id}');
    _log('🚀 price: ${product?.price}');

    if (product == null || !_isStoreAvailable) {
      _log('❌ 상품 또는 Store 사용 불가');
      _log('❌ product null: ${product == null}');
      _log('❌ store available: $_isStoreAvailable');

      _setError(
        PurchaseServiceError.productUnavailable,
        '구매할 상품 정보를 아직 불러오지 못했어요.',
      );
      _notifySafely();

      return false;
    }

    if (_isPurchasing) {
      _log('🟡 이미 결제가 진행 중이라 중복 호출을 막았어요.');
      return false;
    }

    _isPurchasing = true;
    _clearErrorState();
    _notifySafely();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);

      _log('🔥 buyNonConsumable 호출 직전');
      _log('🔥 product ID: ${product.id}');
      _log('🔥 product price: ${product.price}');

      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      _log('🔥 buyNonConsumable 호출 완료');
      _log('🔥 started: $started');

      if (!started) {
        _isPurchasing = false;
        _setError(PurchaseServiceError.purchaseStartFailed, '결제를 시작하지 못했어요.');

        _log('❌ StoreKit이 결제 시작 요청을 거절했어요.');

        _notifySafely();
      } else {
        _log('✅ StoreKit 결제 요청 시작 성공');
        _log('✅ 이제 purchaseStream 응답을 기다려요.');
      }

      return started;
    } catch (error, stackTrace) {
      _log('❌ buyNonConsumable 예외 발생');
      _log('❌ error: $error');
      _log('❌ stackTrace: $stackTrace');

      _isPurchasing = false;
      _setError(
        PurchaseServiceError.purchaseStartFailed,
        '결제를 시작하는 중 문제가 발생했어요.',
      );

      _notifySafely();

      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (_isRestoring) {
      _log('🟡 이미 구매 복원을 진행 중이에요.');
      return;
    }

    _log('');
    _log('========================================');
    _log('♻️ 구매 복원 시작');
    _log('========================================');

    _isRestoring = true;
    _clearErrorState();

    _notifySafely();

    try {
      await _inAppPurchase.restorePurchases();

      _log('✅ restorePurchases 호출 완료');
      _log('✅ purchaseStream 응답을 기다려요.');

      unawaited(
        Future<void>.delayed(_restoreTimeout).then((_) {
          if (_isDisposed || !_isRestoring) return;

          _isRestoring = false;
          _notifySafely();
        }),
      );
    } catch (error, stackTrace) {
      _log('❌ 구매 복원 예외 발생');
      _log('❌ error: $error');
      _log('❌ stackTrace: $stackTrace');

      _isRestoring = false;
      _setError(PurchaseServiceError.restoreFailed, '구매 내역을 복원하지 못했어요.');

      _notifySafely();
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    _log('');
    _log('========================================');
    _log('📦 purchaseStream 업데이트 수신');
    _log('📦 purchase count: ${purchases.length}');
    _log('========================================');

    if (purchases.isEmpty) {
      _log('🟡 구매 업데이트가 비어 있어요.');

      _isPurchasing = false;
      _isRestoring = false;

      _notifySafely();
      return;
    }

    for (final purchase in purchases) {
      _log('');
      _log('📦 productID: ${purchase.productID}');
      _log('📦 status: ${purchase.status}');
      _log(
        '📦 pendingCompletePurchase: '
        '${purchase.pendingCompletePurchase}',
      );
      _log('📦 error: ${purchase.error}');
      _log('📦 purchaseID: ${purchase.purchaseID}');
      _log('📦 transactionDate: ${purchase.transactionDate}');

      if (purchase.productID != duplicateCleanupProductId) {
        _log('🟡 포무 상품이 아닌 구매 업데이트예요.');

        await _completePurchaseIfNeeded(purchase);
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _log('⏳ 결제 승인 대기 중');

          _isPurchasing = true;
          break;

        case PurchaseStatus.purchased:
          _log('✅ 구매 완료 상태 수신');

          final isValid = await _verifyPurchase(purchase);

          if (isValid) {
            _log('✅ 구매 검증 성공');

            await PurchaseAccessService.instance
                .markDuplicateCleanupPurchased();

            _clearErrorState();
          } else {
            _log('❌ 구매 검증 실패');

            _setError(
              PurchaseServiceError.purchaseVerificationFailed,
              '구매 확인에 실패했어요.',
            );
          }

          _isPurchasing = false;
          _isRestoring = false;
          break;

        case PurchaseStatus.restored:
          _log('♻️ 구매 복원 상태 수신');

          final isValid = await _verifyPurchase(purchase);

          if (isValid) {
            _log('✅ 복원 구매 검증 성공');

            await PurchaseAccessService.instance
                .markDuplicateCleanupPurchased();

            _clearErrorState();
          } else {
            _log('❌ 복원 구매 검증 실패');

            _setError(
              PurchaseServiceError.purchaseVerificationFailed,
              '구매 확인에 실패했어요.',
            );
          }

          _isPurchasing = false;
          _isRestoring = false;
          break;

        case PurchaseStatus.error:
          _log('❌ 구매 오류 상태 수신');
          _log('❌ purchase error: ${purchase.error}');

          _isPurchasing = false;
          _isRestoring = false;
          _setError(
            PurchaseServiceError.purchaseFailed,
            purchase.error?.message ?? '결제를 완료하지 못했어요.',
          );
          break;

        case PurchaseStatus.canceled:
          _log('🟡 사용자가 결제를 취소했어요.');

          _isPurchasing = false;
          _isRestoring = false;
          _clearErrorState();
          break;
      }

      await _completePurchaseIfNeeded(purchase);
    }

    _notifySafely();
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    _log('');
    _log('🔍 구매 검증 시작');
    _log('🔍 productID: ${purchase.productID}');
    _log('🔍 status: ${purchase.status}');

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

    _log('🔍 검증 결과: $isValid');

    return isValid;
  }

  Future<void> _completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) {
      _log('🟡 completePurchase가 필요하지 않아요.');
      return;
    }

    _log('🔵 completePurchase 호출 시작');

    try {
      await _inAppPurchase.completePurchase(purchase);

      _log('✅ completePurchase 완료');
    } catch (error, stackTrace) {
      _log('❌ completePurchase 오류');
      _log('❌ error: $error');
      _log('❌ stackTrace: $stackTrace');

      _setError(PurchaseServiceError.completionFailed, '구매 완료 처리 중 문제가 발생했어요.');
    }
  }

  void _setError(PurchaseServiceError code, String fallbackMessage) {
    _errorCode = code;
    _errorMessage = fallbackMessage;
  }

  void _clearErrorState() {
    _errorCode = null;
    _errorMessage = null;
  }

  void clearError() {
    if (_errorMessage == null) return;

    _log('🧹 결제 오류 메시지 초기화');

    _clearErrorState();
    _notifySafely();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifySafely();
  }

  @override
  void dispose() {
    _log('🟣 InAppPurchaseService dispose');

    _isDisposed = true;
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;

    super.dispose();
  }
}
