import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseAccessService extends ChangeNotifier {
  PurchaseAccessService._();

  static final PurchaseAccessService instance = PurchaseAccessService._();

  static const String _hasUsedFreeDeleteKey =
      'purchase_access_has_used_free_delete';

  static const String _isDuplicateCleanupPurchasedKey =
      'purchase_access_duplicate_cleanup_purchased';

  bool _isInitialized = false;
  bool _hasUsedFreeDelete = false;
  bool _isDuplicateCleanupPurchased = false;

  bool get isInitialized => _isInitialized;

  /// 첫 번째 중복 그룹 무료 삭제를 이미 사용했는지
  bool get hasUsedFreeDelete => _hasUsedFreeDelete;

  /// 중복 사진 정리 영구 이용권을 구매했는지
  bool get isDuplicateCleanupPurchased => _isDuplicateCleanupPurchased;

  /// 현재 사용자가 중복 그룹을 삭제할 수 있는지
  bool get canDeleteDuplicateGroup =>
      _isDuplicateCleanupPurchased || !_hasUsedFreeDelete;

  /// 현재 삭제가 무료 삭제인지
  bool get isNextDeleteFree =>
      !_isDuplicateCleanupPurchased && !_hasUsedFreeDelete;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    _hasUsedFreeDelete = prefs.getBool(_hasUsedFreeDeleteKey) ?? false;

    _isDuplicateCleanupPurchased =
        prefs.getBool(_isDuplicateCleanupPurchasedKey) ?? false;

    _isInitialized = true;
    notifyListeners();
  }

  /// 실제 사진 삭제가 성공한 뒤에만 호출해야 함
  Future<void> markFreeDeleteUsed() async {
    if (_hasUsedFreeDelete || _isDuplicateCleanupPurchased) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_hasUsedFreeDeleteKey, true);

    _hasUsedFreeDelete = true;
    notifyListeners();
  }

  /// 결제 성공 후 호출
  Future<void> markDuplicateCleanupPurchased() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isDuplicateCleanupPurchasedKey, true);

    _isDuplicateCleanupPurchased = true;
    notifyListeners();
  }

  /// 구매 복원 결과를 반영할 때 사용
  Future<void> updatePurchaseStatus({required bool isPurchased}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isDuplicateCleanupPurchasedKey, isPurchased);

    _isDuplicateCleanupPurchased = isPurchased;
    notifyListeners();
  }

  /// 개발 중 무료 삭제 상태를 다시 테스트할 때만 사용
  @visibleForTesting
  Future<void> debugResetAccess() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_hasUsedFreeDeleteKey);
    await prefs.remove(_isDuplicateCleanupPurchasedKey);

    _hasUsedFreeDelete = false;
    _isDuplicateCleanupPurchased = false;
    notifyListeners();
  }
}
