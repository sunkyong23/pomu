import 'package:shared_preferences/shared_preferences.dart';

class DuplicateHistoryService {
  static const String _key = 'duplicate_resolved_groups';

  Future<Set<String>> loadResolvedGroups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  Future<void> saveResolvedGroup(String groupKey) async {
    final prefs = await SharedPreferences.getInstance();

    final current = prefs.getStringList(_key) ?? [];

    if (current.contains(groupKey)) return;

    current.add(groupKey);
    await prefs.setStringList(_key, current);
  }

  Future<void> clearResolvedGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
