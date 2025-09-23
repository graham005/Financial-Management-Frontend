import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/org_settings.dart';

class SettingsNotifier extends StateNotifier<OrganizationSettings> {
  static const _key = 'org_settings';
  SettingsNotifier() : super(const OrganizationSettings(name: '', address: '', phone: '', email: '') ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = OrganizationSettings.fromJsonString(raw);
      } catch (_) {}
    }
  }

  Future<void> save(OrganizationSettings s) async {
    state = s;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, s.toJsonString());
  }

  Future<void> updateFields({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? defaultPrinterId,
    String? defaultPaperSize,
    String? receiptTemplate,
  }) async {
    final updated = state.copyWith(
      name: name,
      address: address,
      phone: phone,
      email: email,
      logoUrl: logoUrl,
      defaultPrinterId: defaultPrinterId,
      defaultPaperSize: defaultPaperSize,
      receiptTemplate: receiptTemplate,
    );
    await save(updated);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, OrganizationSettings>(
  (ref) => SettingsNotifier(),
);