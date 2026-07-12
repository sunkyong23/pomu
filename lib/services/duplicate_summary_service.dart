import 'package:shared_preferences/shared_preferences.dart';

class DuplicateSummary {
  final bool hasScanned;
  final int groupCount;
  final int deleteCandidateCount;
  final int reclaimableBytes;
  final DateTime? scannedAt;

  const DuplicateSummary({
    required this.hasScanned,
    required this.groupCount,
    required this.deleteCandidateCount,
    required this.reclaimableBytes,
    required this.scannedAt,
  });

  const DuplicateSummary.empty()
    : hasScanned = false,
      groupCount = 0,
      deleteCandidateCount = 0,
      reclaimableBytes = 0,
      scannedAt = null;
}

class DuplicateSummaryService {
  static const _hasScannedKey = 'duplicate_summary_has_scanned';
  static const _groupCountKey = 'duplicate_summary_group_count';
  static const _deleteCandidateCountKey =
      'duplicate_summary_delete_candidate_count';
  static const _reclaimableBytesKey = 'duplicate_summary_reclaimable_bytes';
  static const _scannedAtKey = 'duplicate_summary_scanned_at';

  Future<DuplicateSummary> loadSummary() async {
    final prefs = await SharedPreferences.getInstance();

    final hasScanned = prefs.getBool(_hasScannedKey) ?? false;

    if (!hasScanned) {
      return const DuplicateSummary.empty();
    }

    final scannedAtValue = prefs.getString(_scannedAtKey);

    return DuplicateSummary(
      hasScanned: true,
      groupCount: prefs.getInt(_groupCountKey) ?? 0,
      deleteCandidateCount: prefs.getInt(_deleteCandidateCountKey) ?? 0,
      reclaimableBytes: prefs.getInt(_reclaimableBytesKey) ?? 0,
      scannedAt: scannedAtValue == null
          ? null
          : DateTime.tryParse(scannedAtValue),
    );
  }

  Future<void> saveSummary({
    required int groupCount,
    required int deleteCandidateCount,
    required int reclaimableBytes,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_hasScannedKey, true);
    await prefs.setInt(_groupCountKey, groupCount);
    await prefs.setInt(_deleteCandidateCountKey, deleteCandidateCount);
    await prefs.setInt(_reclaimableBytesKey, reclaimableBytes);
    await prefs.setString(_scannedAtKey, DateTime.now().toIso8601String());
  }

  Future<void> clearSummary() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_hasScannedKey);
    await prefs.remove(_groupCountKey);
    await prefs.remove(_deleteCandidateCountKey);
    await prefs.remove(_reclaimableBytesKey);
    await prefs.remove(_scannedAtKey);
  }
}
