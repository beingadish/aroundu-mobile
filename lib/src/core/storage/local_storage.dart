import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Provides lightweight device persistence for session and app UI state.
class LocalStorage {
  const LocalStorage();

  static const String _authSessionKey = 'auth.session.v1';
  static const String _providerTabIndexKey = 'ui.provider_tab_index.v1';
  static const String _workerTabIndexKey = 'ui.worker_tab_index.v1';
  static const String _adminTabIndexKey = 'ui.admin_tab_index.v1';
  static const String _workerSkillsKey = 'ui.worker_skills.v1';
  static const String _themeModeKey = 'ui.theme_mode.v1';

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> readAuthSession() async {
    final prefs = await _prefs();
    if (prefs == null) {
      return null;
    }
    final raw = prefs.getString(_authSessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      await prefs.remove(_authSessionKey);
    }

    return null;
  }

  Future<void> saveAuthSession(Map<String, dynamic> session) async {
    final prefs = await _prefs();
    if (prefs == null) {
      return;
    }
    await prefs.setString(_authSessionKey, jsonEncode(session));
  }

  Future<void> clearAuthSession() async {
    final prefs = await _prefs();
    if (prefs == null) {
      return;
    }
    await prefs.remove(_authSessionKey);
  }

  Future<int?> readProviderTabIndex() async {
    final prefs = await _prefs();
    if (prefs == null) {
      return null;
    }
    return prefs.getInt(_providerTabIndexKey);
  }

  Future<void> saveProviderTabIndex(int index) async {
    final prefs = await _prefs();
    if (prefs == null) {
      return;
    }
    await prefs.setInt(_providerTabIndexKey, index);
  }

  Future<int?> readWorkerTabIndex() async {
    final prefs = await _prefs();
    if (prefs == null) {
      return null;
    }
    return prefs.getInt(_workerTabIndexKey);
  }

  Future<void> saveWorkerTabIndex(int index) async {
    final prefs = await _prefs();
    if (prefs == null) {
      return;
    }
    await prefs.setInt(_workerTabIndexKey, index);
  }

  Future<int?> readAdminTabIndex() async {
    final prefs = await _prefs();
    if (prefs == null) {
      return null;
    }
    return prefs.getInt(_adminTabIndexKey);
  }

  Future<void> saveAdminTabIndex(int index) async {
    final prefs = await _prefs();
    if (prefs == null) {
      return;
    }
    await prefs.setInt(_adminTabIndexKey, index);
  }

  Future<Set<String>> readWorkerSkills() async {
    final prefs = await _prefs();
    if (prefs == null) {
      return <String>{};
    }
    final values = prefs.getStringList(_workerSkillsKey);
    if (values == null) {
      return <String>{};
    }
    return values.toSet();
  }

  Future<void> saveWorkerSkills(Set<String> skills) async {
    final prefs = await _prefs();
    if (prefs == null) {
      return;
    }
    await prefs.setStringList(_workerSkillsKey, skills.toList()..sort());
  }

  Future<String?> readThemeMode() async {
    final prefs = await _prefs();
    if (prefs == null) {
      return null;
    }
    return prefs.getString(_themeModeKey);
  }

  Future<void> saveThemeMode(String themeModeName) async {
    final prefs = await _prefs();
    if (prefs == null) {
      return;
    }
    await prefs.setString(_themeModeKey, themeModeName);
  }
}
